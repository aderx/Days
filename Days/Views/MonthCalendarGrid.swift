import SwiftUI

private let cellCorner: CGFloat = 7

struct MonthCalendarGrid: View {
    @EnvironmentObject private var model: DaysModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @Namespace private var glassSelectionNamespace

    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                    Text(weekday)
                        .font(.ndMono(11, weight: .medium))
                        .foregroundStyle(isWeekend(index) ? ND.textSecondary(colorScheme) : ND.textDisabled(colorScheme))
                        .frame(maxWidth: .infinity, minHeight: 20)
                }
            }

            if isGlassSkin, #available(macOS 26.0, *) {
                GlassEffectContainer(spacing: 4) {
                    dayGrid
                }
            } else {
                dayGrid
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(model.visibleDays) { day in
                DayCellView(
                    day: day,
                    holidays: model.holidays(on: day.date),
                    isSelected: CalendarMath.isSameDay(day.date, model.selectedDate),
                    isToday: CalendarMath.isSameDay(day.date, Date()),
                    isWeekend: CalendarMath.isWeekend(day.date),
                    theme: model.settings.calendarTheme,
                    glassNamespace: glassSelectionNamespace
                ) {
                    withAnimation(.easeOut(duration: 0.18)) {
                        model.select(day.date)
                    }
                }
            }
        }
    }

    private func isWeekend(_ index: Int) -> Bool {
        // firstWeekday is Monday, so columns 5 (六) and 6 (日) are the weekend.
        index >= 5
    }
}

private struct DayCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isGlassSkin) private var isGlassSkin
    @State private var isHovering = false

    let day: DayCell
    let holidays: [Holiday]
    let isSelected: Bool
    let isToday: Bool
    let isWeekend: Bool
    let theme: CalendarTheme
    let glassNamespace: Namespace.ID
    let action: () -> Void

    /// In glass mode, the selected day is a shared Liquid Glass lens that moves
    /// between dates instead of repainting a flat highlight in each cell.
    private var usesGlassLens: Bool {
        if isGlassSkin, isSelected, #available(macOS 26.0, *) {
            return true
        }
        return false
    }

    private var primaryHoliday: Holiday? {
        holidays.first { $0.kind == .holiday } ?? holidays.first { $0.kind == .workday } ?? holidays.first
    }

    /// Background for an unmarked day — weekends get a subtle shaded band.
    private var normalFill: Color {
        isWeekend ? ND.weekendFill(colorScheme) : ND.dayFill(colorScheme)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top) {
                    Text(CalendarMath.dayNumber(for: day.date))
                        .font(.ndMono(21, weight: .medium))
                        .foregroundStyle(dayColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .fixedSize(horizontal: true, vertical: false)

                    Spacer(minLength: 0)

                    if let primaryHoliday {
                        Text(primaryHoliday.kind.shortLabel)
                            .font(.ndMono(10, weight: .bold))
                            .foregroundStyle(tagColor(for: primaryHoliday.kind))
                    } else if isToday {
                        Circle()
                            .fill(isSelected ? Color.primary : Color.primary.opacity(0.72))
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                    }
                }

                Spacer(minLength: 0)

                if let primaryHoliday {
                    Text(holidayTitle(for: primaryHoliday))
                        .font(.ndMono(8.5))
                        .lineLimit(1)
                        .foregroundStyle(holidayTextColor(for: primaryHoliday.kind))
                        .padding(.bottom, 8)
                } else {
                    Text(" ")
                        .font(.ndMono(8.5))
                        .padding(.bottom, 8)
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 47, maxHeight: 47, alignment: .topLeading)
            .background(cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: cellCorner))
            .overlay { cellBorder }
            .opacity(day.isInDisplayedMonth ? 1 : 0.38)
            .animation(.easeOut(duration: 0.14), value: isHovering)
            .animation(.easeOut(duration: 0.14), value: isSelected)
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }

    @ViewBuilder
    private var cellBackground: some View {
        if usesGlassLens, #available(macOS 26.0, *) {
            Color.clear.glassEffect(
                .regular.interactive(),
                in: .rect(cornerRadius: cellCorner)
            )
            .glassEffectID("selected-day", in: glassNamespace)
        } else {
            background
        }
    }

    @ViewBuilder
    private var cellBorder: some View {
        if usesGlassLens {
            EmptyView()
        } else {
            RoundedRectangle(cornerRadius: cellCorner)
                .stroke(borderColor, lineWidth: borderWidth)
        }
    }

    private var dayColor: Color {
        if isSelected {
            switch theme {
            case .classic:
                return Color.primary
            case .soft:
                return day.isInDisplayedMonth ? ND.textDisplay(colorScheme) : ND.textDisabled(colorScheme)
            }
        }

        return day.isInDisplayedMonth ? ND.textDisplay(colorScheme) : ND.textDisabled(colorScheme)
    }

    private var background: Color {
        switch theme {
        case .classic:
            return classicBackground
        case .soft:
            return softBackground
        }
    }

    private var borderColor: Color {
        switch theme {
        case .classic:
            return classicBorderColor
        case .soft:
            return softBorderColor
        }
    }

    private var borderWidth: CGFloat {
        switch theme {
        case .classic:
            return isToday || isSelected ? 1.5 : 1
        case .soft:
            if isSelected || isHovering {
                return 1.5
            }
            return primaryHoliday == nil ? 1 : 0
        }
    }

    private var classicBackground: Color {
        if isSelected {
            return selectedFillColor
        }

        if isHovering {
            return hoverFillColor
        }

        guard let primaryHoliday else {
            return normalFill
        }

        switch primaryHoliday.kind {
        case .holiday:
            return ND.accent.opacity(colorScheme == .dark ? 0.22 : 0.17)
        case .workday:
            return ND.warning.opacity(colorScheme == .dark ? 0.24 : 0.22)
        case .observance:
            return ND.dayFillStrong(colorScheme)
        }
    }

    private var classicBorderColor: Color {
        if isSelected {
            return selectedFillColor
        }

        if let primaryHoliday {
            switch primaryHoliday.kind {
            case .holiday:
                return ND.accent.opacity(0.7)
            case .workday:
                return ND.warning.opacity(0.7)
            case .observance:
                return ND.borderVisible(colorScheme)
            }
        }

        if isToday {
            return Color.primary.opacity(0.82)
        }

        return isHovering ? Color.primary.opacity(0.16) : Color.primary.opacity(0.08)
    }

    private var softBackground: Color {
        if isHovering && primaryHoliday == nil {
            return hoverFillColor
        }

        if isToday {
            return hoverFillColor
        }

        guard let primaryHoliday else {
            return normalFill
        }

        switch primaryHoliday.kind {
        case .holiday:
            return ND.accent.opacity(colorScheme == .dark ? 0.14 : 0.10)
        case .workday:
            return ND.warning.opacity(colorScheme == .dark ? 0.16 : 0.13)
        case .observance:
            return ND.dayFill(colorScheme)
        }
    }

    private var softBorderColor: Color {
        if let primaryHoliday {
            if isSelected {
                return themeColor(for: primaryHoliday.kind)
            }

            if isHovering {
                return themeColor(for: primaryHoliday.kind).opacity(0.34)
            }

            return Color.clear
        }

        if isSelected {
            return Color.primary
        }

        if isHovering {
            return Color.primary.opacity(0.16)
        }

        if isToday {
            return Color.primary.opacity(0.08)
        }

        return Color.clear
    }

    private var selectedFillColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.16)
    }

    private var hoverFillColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.09)
    }

    private func tagColor(for kind: HolidayKind) -> Color {
        themeColor(for: kind)
    }

    private func holidayTextColor(for kind: HolidayKind) -> Color {
        switch theme {
        case .classic:
            return isSelected ? Color.primary.opacity(0.76) : tagColor(for: kind)
        case .soft:
            return tagColor(for: kind)
        }
    }

    private func holidayTitle(for holiday: Holiday) -> String {
        holidays.count > 1 ? "\(holiday.name)*" : holiday.name
    }

    private func themeColor(for kind: HolidayKind) -> Color {
        switch kind {
        case .holiday:
            return ND.accent
        case .workday:
            return ND.warning
        case .observance:
            return ND.textSecondary(colorScheme)
        }
    }
}
