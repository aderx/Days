import AppKit
import SwiftUI

private let sharedHoverFill = Color.primary.opacity(0.10)

struct CalendarPanelView: View {
    @EnvironmentObject private var model: DaysModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDateEditorPresented = false
    @State private var isDateControlHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            MonthCalendarGrid()
        }
        .padding(12)
        .frame(width: 456)
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
                        isDateEditorPresented = true
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
                .popover(isPresented: $isDateEditorPresented, arrowEdge: .top) {
                    YearMonthEditorView()
                        .environmentObject(model)
                }
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
final class SettingsWindowPresenter {
    static let shared = SettingsWindowPresenter()

    private var window: NSWindow?

    func show(model: DaysModel) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView()
            .environmentObject(model)
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Days 设置"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
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
