import Foundation

enum CalendarMath {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? startOfDay(date)
    }

    static func monthTitle(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d / %02d", components.year ?? 0, components.month ?? 0)
    }

    static func yearUnitText(for date: Date) -> String {
        let year = calendar.component(.year, from: date)
        return String(format: "%04d年", year)
    }

    static func monthUnitText(for date: Date) -> String {
        let month = calendar.component(.month, from: date)
        return String(format: "%02d月", month)
    }

    static func yearMonthUnitText(for date: Date) -> String {
        "\(yearUnitText(for: date))\(monthUnitText(for: date))"
    }

    static func chineseFullDate(_ date: Date, includeYear: Bool = true, includeWeekday: Bool = true) -> String {
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        var text = includeYear
            ? String(format: "%04d年%02d月%02d日", year, month, day)
            : String(format: "%02d月%02d日", month, day)

        if includeWeekday {
            text += " \(weekdayText(for: date))"
        }

        return text
    }

    static func weekdayText(for date: Date) -> String {
        let index = calendar.component(.weekday, from: date)
        let symbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return symbols[max(0, min(index - 1, symbols.count - 1))]
    }

    static func dateKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func dayNumber(for date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    static func year(for date: Date) -> Int {
        calendar.component(.year, from: date)
    }

    static func month(for date: Date) -> Int {
        calendar.component(.month, from: date)
    }

    static func day(for date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func addMonths(_ count: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: count, to: startOfMonth(for: date)) ?? date
    }

    static func addYears(_ count: Int, to date: Date) -> Date {
        calendar.date(byAdding: .year, value: count, to: startOfMonth(for: date)) ?? date
    }

    static func clampedDate(year: Int, month: Int, preferredDay: Int) -> Date {
        let safeMonth = max(1, min(12, month))
        let firstOfMonth = calendar.date(from: DateComponents(year: year, month: safeMonth, day: 1)) ?? Date()
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
        let maxDay = range?.count ?? 28
        let safeDay = max(1, min(maxDay, preferredDay))
        return calendar.date(from: DateComponents(year: year, month: safeMonth, day: safeDay)) ?? firstOfMonth
    }

    static func makeVisibleDays(for month: Date) -> [DayCell] {
        let firstOfMonth = startOfMonth(for: month)
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingDays = (weekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: firstOfMonth) ?? firstOfMonth

        return (0..<42).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else {
                return nil
            }
            return DayCell(
                date: date,
                isInDisplayedMonth: calendar.isDate(date, equalTo: firstOfMonth, toGranularity: .month)
            )
        }
    }
}
