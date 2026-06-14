import AppKit
import SwiftUI

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
                        dismissDateEditor()
                    }
                    .zIndex(1)

                inlineDateEditor
                    .offset(x: 0, y: 84)
                    .zIndex(2)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading)))
            }
        }
        .padding(14)
        .frame(width: 456, height: 448, alignment: .topLeading)
        .background(Color.clear)
        .environment(\.isGlassSkin, isGlassSkin)
        .onExitCommand(perform: dismissDateEditor)
    }

    private var isGlassSkin: Bool {
        model.settings.panelSkin == .glass && PanelSkin.glassAvailable
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(model.selectedMonthDayTitle)
                    .font(.ndDisplay(42))
                    .foregroundStyle(selectedDayNumberColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: true, vertical: false)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.18), value: model.selectedMonthDayTitle)

                controlRow
            }
            .frame(minWidth: 150, minHeight: 70, alignment: .topLeading)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                if model.selectedHolidays.isEmpty {
                    Text(emptyScheduleText)
                        .font(.ndMono(12))
                        .foregroundStyle(ND.textDisabled(colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    ForEach(model.selectedHolidays.prefix(3)) { holiday in
                        HolidayTag(title: displayTitle(for: holiday), color: holidayColor(for: holiday.kind))
                    }
                }
            }
            .frame(width: 140, height: 70, alignment: .topTrailing)
        }
        .frame(height: 70)
    }

    private var controlRow: some View {
        HStack(spacing: 4) {
            NavIconButton(systemImage: "chevron.left", help: "上个月") {
                withAnimation(.easeOut(duration: 0.16)) {
                    model.changeSelectedMonth(by: -1)
                }
            }

            Button {
                withAnimation(.easeOut(duration: 0.16)) {
                    isDateEditorPresented.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(model.selectedYearTitle)
                        .font(.ndMono(12, weight: .medium))
                        .foregroundStyle(selectedYearMonthColor)

                    Text(weekdayText)
                        .font(.ndMono(12))
                        .foregroundStyle(ND.textSecondary(colorScheme))

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(dateSwitchIconColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .glassControlBackground(isGlass: isGlassSkin, isHovering: isDateControlHovering, shape: Capsule())
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.14), value: isDateControlHovering)
            }
            .buttonStyle(.plain)
            .pointingHandOnHover($isDateControlHovering)
            .help("切换年月")

            NavIconButton(systemImage: "chevron.right", help: "下个月") {
                withAnimation(.easeOut(duration: 0.16)) {
                    model.changeSelectedMonth(by: 1)
                }
            }

            if model.shouldShowTodayShortcut {
                TodayButton {
                    withAnimation(.easeOut(duration: 0.16)) {
                        model.goToToday()
                    }
                }
                .help("回到今天")
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .animation(.easeOut(duration: 0.16), value: model.shouldShowTodayShortcut)
    }

    private var weekdayText: String {
        CalendarMath.weekdayText(for: model.selectedDate)
    }

    private var emptyScheduleText: String {
        CalendarMath.isSameDay(model.selectedDate, Date()) ? "今天暂时没有安排" : "这天暂时没有安排"
    }

    @ViewBuilder
    private var inlineDateEditor: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        if model.settings.panelSkin == .glass, #available(macOS 26.0, *) {
            YearMonthEditorView()
                .environmentObject(model)
                .glassEffect(.regular.interactive(), in: shape)
                .fixedSize()
        } else {
            YearMonthEditorView()
                .environmentObject(model)
                .background {
                    shape
                        .fill(.ultraThinMaterial)
                        .overlay { shape.fill(ND.panelChromeFill(colorScheme)) }
                        .overlay { shape.stroke(ND.panelStroke(colorScheme), lineWidth: 0.8) }
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.16), radius: 18, x: 0, y: 8)
                }
                .fixedSize()
        }
    }

    private func dismissDateEditor() {
        guard isDateEditorPresented else {
            return
        }

        withAnimation(.easeOut(duration: 0.14)) {
            isDateEditorPresented = false
        }
    }

    private var dateSwitchIconColor: Color {
        let base = isDateControlHovering ? ND.textPrimary(colorScheme) : ND.textSecondary(colorScheme)
        return base.opacity(isDateControlHovering ? 0.68 : 0.48)
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

private struct HolidayTag: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 3, height: 11)
            Text(title)
                .font(.ndMono(12, weight: .medium))
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }
}

private struct NavIconButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let systemImage: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isHovering ? ND.textPrimary(colorScheme) : ND.textSecondary(colorScheme))
                .frame(width: 22, height: 22)
                .glassControlBackground(isGlass: isGlassSkin, isHovering: isHovering, shape: Circle())
                .animation(.easeOut(duration: 0.14), value: isHovering)
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
        .help(help)
    }
}

private struct TodayButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(ND.textPrimary(colorScheme))
                .frame(width: 20, height: 20)
                .glassControlBackground(isGlass: isGlassSkin, isHovering: isHovering, shape: Circle())
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
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 560),
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
    @Environment(\.isGlassSkin) private var isGlassSkin
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
        VStack(alignment: .leading, spacing: 8) {
            EditorArrowButton(
                systemImage: "chevron.up",
                width: inputWidth + 16,
                helpText: "增加\(title)",
                action: increment
            )

            HStack(spacing: 8) {
                TextField(title, text: text)
                    .font(.ndMono(18, weight: .medium))
                    .foregroundStyle(ND.textPrimary(colorScheme))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(width: inputWidth, height: 30)
                    .onSubmit(apply)
                    .padding(.horizontal, 8)
                    .background { editorFieldBackground }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.ndMono(13, weight: .medium))
                    .foregroundStyle(ND.textSecondary(colorScheme))
                    .frame(width: 14, alignment: .leading)
            }
            .frame(width: controlWidth, alignment: .leading)

            EditorArrowButton(
                systemImage: "chevron.down",
                width: inputWidth + 16,
                helpText: "减少\(title)",
                action: decrement
            )
        }
        .frame(width: controlWidth)
    }

    @ViewBuilder
    private var editorFieldBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        if isGlassSkin, #available(macOS 26.0, *) {
            Color.clear.glassEffect(.regular.interactive(), in: shape)
        } else {
            shape.fill(ND.surface(colorScheme))
        }
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
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let systemImage: String
    let width: CGFloat
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ND.textPrimary(colorScheme))
                .frame(width: width, height: 22)
                .glassControlBackground(isGlass: isGlassSkin, isHovering: isHovering, shape: Capsule())
                .animation(.easeOut(duration: 0.14), value: isHovering)
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
        .help(helpText)
    }
}
