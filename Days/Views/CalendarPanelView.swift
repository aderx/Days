import AppKit
import SwiftUI

private let sharedHoverFill = Color.primary.opacity(0.10)

struct CalendarPanelView: View {
    @EnvironmentObject private var model: DaysModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDateEditorPresented = false
    @State private var isDateControlHovering = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 10) {
                header

                MonthCalendarGrid()
            }
            .zIndex(0)

            if isDateEditorPresented {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.14)) {
                            isDateEditorPresented = false
                        }
                    }
                    .zIndex(1)

                inlineDateEditor
                    .offset(x: 0, y: 82)
                    .zIndex(2)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading)))
            }
        }
        .padding(12)
        .frame(width: 456, height: 448, alignment: .topLeading)
        .environment(\.colorScheme, .light)
        .background(Color.clear)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(model.selectedDayNumber)
                        .font(.ndDisplay(54))
                        .foregroundStyle(selectedDayNumberColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: true, vertical: false)

                    if model.shouldShowTodayShortcut {
                        TodayButton {
                            model.goToToday()
                        }
                        .help("回到今天")
                    }
                }
                .frame(minWidth: 66, alignment: .leading)

                Button {
                    withAnimation(.easeOut(duration: 0.16)) {
                        isDateEditorPresented.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(model.selectedYearMonthTitle)
                            .font(.ndMono(12))
                            .foregroundStyle(selectedYearMonthColor)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(isDateControlHovering ? ND.textPrimary(colorScheme) : ND.textSecondary(colorScheme))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isDateControlHovering ? hoverFill : Color.clear)
                    .clipShape(Capsule())
                    .contentShape(Rectangle())
                    .animation(.easeOut(duration: 0.14), value: isDateControlHovering)
                }
                .buttonStyle(.plain)
                .pointingHandOnHover($isDateControlHovering)
            }

            Spacer()

            if !model.selectedHolidays.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(model.selectedHolidays.prefix(2)) { holiday in
                        Text(displayTitle(for: holiday))
                            .font(.ndMono(12, weight: .medium))
                            .foregroundStyle(holidayColor(for: holiday.kind))
                            .lineLimit(1)
                    }
                }
                .frame(maxHeight: 74, alignment: .center)
            }
        }
    }

    private var inlineDateEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            PanelArrow()
                .fill(.ultraThinMaterial)
                .frame(width: 24, height: 10)
                .padding(.leading, 22)
                .overlay(alignment: .leading) {
                    PanelArrow()
                        .stroke(Color.black.opacity(0.12), lineWidth: 0.7)
                        .frame(width: 24, height: 10)
                        .padding(.leading, 22)
                }

            YearMonthEditorView()
                .environmentObject(model)
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.14), lineWidth: 0.8)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 8)
        }
    }

    private var hoverFill: Color {
        sharedHoverFill
    }

    private var selectedDayNumberColor: Color {
        guard let holiday = model.selectedHolidays.first(where: { $0.kind == .holiday })
            ?? model.selectedHolidays.first(where: { $0.kind == .workday })
            ?? model.selectedHolidays.first
        else {
            return ND.textDisplay(colorScheme)
        }

        return holidayColor(for: holiday.kind)
    }

    private var selectedYearMonthColor: Color {
        guard let holiday = model.selectedHolidays.first(where: { $0.kind == .holiday })
            ?? model.selectedHolidays.first(where: { $0.kind == .workday })
            ?? model.selectedHolidays.first
        else {
            return isDateControlHovering ? ND.textPrimary(colorScheme) : ND.textSecondary(colorScheme)
        }

        return holidayColor(for: holiday.kind)
    }

    private func holidayColor(for kind: HolidayKind) -> Color {
        switch kind {
        case .holiday:
            return ND.accent
        case .workday:
            return ND.warning
        case .observance:
            return ND.textSecondary(colorScheme)
        }
    }

    private func displayTitle(for holiday: Holiday) -> String {
        switch holiday.kind {
        case .holiday:
            return "\(holiday.name)休假"
        case .workday:
            return "\(holiday.name)补班"
        case .observance:
            return holiday.name
        }
    }
}

private struct PanelArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct TodayButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ND.textPrimary(colorScheme))
                .frame(width: 26, height: 24)
                .background(isHovering ? sharedHoverFill : Color.clear)
                .clipShape(Capsule())
                .animation(.easeOut(duration: 0.14), value: isHovering)
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }
}

@MainActor
final class SettingsWindowPresenter: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowPresenter()

    private var window: NSWindow?

    func show(model: DaysModel) {
        if let window, window.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            window.level = .floating
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            return
        } else if window != nil {
            releaseSettingsWindow()
        }

        let view = SettingsView()
            .environmentObject(model)
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Days 设置"
        window.contentView = hostingView
        window.center()
        window.level = .floating
        window.delegate = self
        window.isReleasedWhenClosed = false
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            guard notification.object as AnyObject === self.window else {
                return
            }

            self.releaseSettingsWindow()
        }
    }

    private func releaseSettingsWindow() {
        guard let window else {
            return
        }

        window.delegate = nil
        window.contentView = nil
        self.window = nil
    }
}

private struct YearMonthEditorView: View {
    @EnvironmentObject private var model: DaysModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var yearText = ""
    @State private var monthText = ""

    var body: some View {
        HStack(spacing: 20) {
            editorColumn(
                title: "年",
                inputWidth: 82,
                controlWidth: 112,
                text: $yearText,
                decrement: {
                    model.changeSelectedYear(by: -1)
                    reload()
                },
                increment: {
                    model.changeSelectedYear(by: 1)
                    reload()
                },
                apply: applyYear
            )

            editorColumn(
                title: "月",
                inputWidth: 44,
                controlWidth: 76,
                text: $monthText,
                decrement: {
                    model.changeSelectedMonth(by: -1)
                    reload()
                },
                increment: {
                    model.changeSelectedMonth(by: 1)
                    reload()
                },
                apply: applyMonth
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .fixedSize()
        .background(Color.clear)
        .onAppear(perform: reload)
    }

    private func editorColumn(
        title: String,
        inputWidth: CGFloat,
        controlWidth: CGFloat,
        text: Binding<String>,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void,
        apply: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            EditorArrowButton(systemImage: "chevron.up", width: controlWidth, action: increment)

            HStack(spacing: 8) {
                TextField(title, text: text)
                    .font(.ndMono(18, weight: .medium))
                    .foregroundStyle(ND.textPrimary(colorScheme))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(width: inputWidth, height: 30)
                    .onSubmit(apply)
                    .padding(.horizontal, 8)
                    .background(ND.surface(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(title)
                    .font(.ndMono(13, weight: .medium))
                    .foregroundStyle(ND.textSecondary(colorScheme))
                    .frame(width: 14, alignment: .leading)
            }

            EditorArrowButton(systemImage: "chevron.down", width: controlWidth, action: decrement)
        }
        .frame(width: controlWidth)
    }

    private func reload() {
        yearText = "\(CalendarMath.year(for: model.selectedDate))"
        monthText = "\(CalendarMath.month(for: model.selectedDate))"
    }

    private func applyYear() {
        guard let year = Int(yearText) else {
            reload()
            return
        }
        model.updateSelectedDate(year: year, month: CalendarMath.month(for: model.selectedDate))
        reload()
    }

    private func applyMonth() {
        guard let month = Int(monthText) else {
            reload()
            return
        }
        model.updateSelectedDate(year: CalendarMath.year(for: model.selectedDate), month: month)
        reload()
    }
}

private struct EditorArrowButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    let systemImage: String
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ND.textPrimary(colorScheme))
                .frame(width: width, height: 22)
                .background(isHovering ? sharedHoverFill : Color.clear)
                .clipShape(Capsule())
                .animation(.easeOut(duration: 0.14), value: isHovering)
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }
}
