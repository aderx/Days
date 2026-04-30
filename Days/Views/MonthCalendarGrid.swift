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
                        isToday: CalendarMath.isSameDay(day.date, Date())
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
    let action: () -> Void

    private var primaryHoliday: Holiday? {
        holidays.first { $0.kind == .holiday } ?? holidays.first { $0.kind == .workday } ?? holidays.first
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
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
                    Text(primaryHoliday.name)
                        .font(.ndMono(8.5))
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.primary.opacity(0.76) : tagColor(for: primaryHoliday.kind))
                } else {
                    Text(" ")
                        .font(.ndMono(8.5))
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 54, maxHeight: 54, alignment: .topLeading)
            .background(background)
            .overlay {
                Rectangle()
                    .stroke(borderColor, lineWidth: isToday || isSelected ? 1.5 : 1)
            }
            .opacity(day.isInDisplayedMonth ? 1 : 0.38)
            .animation(.easeOut(duration: 0.14), value: isHovering)
        }
        .buttonStyle(.plain)
        .pointingHandOnHover($isHovering)
    }

    private var dayColor: Color {
        if isSelected {
            return Color.primary
        }

        return day.isInDisplayedMonth ? ND.textDisplay(colorScheme) : ND.textDisabled(colorScheme)
    }

    private var background: Color {
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

    private var borderColor: Color {
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

    private var selectedFillColor: Color {
        Color.primary.opacity(0.16)
    }

    private var hoverFillColor: Color {
        Color.primary.opacity(0.09)
    }

    private func tagColor(for kind: HolidayKind) -> Color {
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
