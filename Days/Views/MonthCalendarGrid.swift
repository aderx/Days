import SwiftUI

struct MonthCalendarGrid: View {
    @EnvironmentObject private var model: DaysModel
    @Environment(\.colorScheme) private var colorScheme

    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.ndMono(11, weight: .medium))
                        .foregroundStyle(ND.textSecondary(colorScheme))
                        .frame(maxWidth: .infinity, minHeight: 20)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(model.visibleDays) { day in
                    DayCellView(
                        day: day,
                        holidays: model.holidays(on: day.date),
                        isSelected: CalendarMath.isSameDay(day.date, model.selectedDate),
                        isToday: CalendarMath.isSameDay(day.date, Date()),
                        theme: model.settings.calendarTheme
                    ) {
                        model.select(day.date)
                    }
                }
            }
        }
    }
}

private struct DayCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    let day: DayCell
    let holidays: [Holiday]
    let isSelected: Bool
    let isToday: Bool
    let theme: CalendarTheme
    let action: () -> Void

    private var primaryHoliday: Holiday? {
        holidays.first { $0.kind == .holiday } ?? holidays.first { $0.kind == .workday } ?? holidays.first
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
            .background(background)
            .overlay {
                Rectangle()
                    .stroke(borderColor, lineWidth: borderWidth)
            }
            .opacity(day.isInDisplayedMonth ? 1 : 0.38)
            .animation(.easeOut(duration: 0.14), value: isHovering)
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
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
            return Color.white.opacity(0.34)
        }

        switch primaryHoliday.kind {
        case .holiday:
            return ND.accent.opacity(0.17)
        case .workday:
            return ND.warning.opacity(0.22)
        case .observance:
            return Color.white.opacity(0.40)
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
        if isToday {
            return hoverFillColor
        }

        guard let primaryHoliday else {
            return Color.white.opacity(0.34)
        }

        switch primaryHoliday.kind {
        case .holiday:
            return ND.accent.opacity(0.10)
        case .workday:
            return ND.warning.opacity(0.13)
        case .observance:
            return Color.white.opacity(0.34)
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
        Color.primary.opacity(0.16)
    }

    private var hoverFillColor: Color {
        Color.primary.opacity(0.09)
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
