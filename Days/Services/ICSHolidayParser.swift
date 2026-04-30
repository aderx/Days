import Foundation

enum ICSHolidayParser {
    static func parse(_ text: String) -> [Holiday] {
        let lines = unfoldLines(in: text)
        let events = extractEvents(from: lines)
        var holidays: [Holiday] = []

        for event in events {
            guard let startValue = event["DTSTART"],
                  let start = parseDate(startValue),
                  let summary = event["SUMMARY"]
            else {
                continue
            }

            let kind = holidayKind(from: event, summary: summary)
            let name = clean(summary)
            let end = event["DTEND"].flatMap(parseDate)

            if let recurrence = event["RRULE"],
               recurrence.contains("FREQ=YEARLY") {
                let count = recurrenceCount(from: recurrence) ?? 6
                holidays.append(contentsOf: expandYearly(start: start, count: count, name: name, kind: kind))
            } else {
                holidays.append(contentsOf: expandRange(start: start, end: end, name: name, kind: kind))
            }
        }

        return Array(Set(holidays)).sorted {
            if $0.dateKey == $1.dateKey {
                return $0.name < $1.name
            }
            return $0.dateKey < $1.dateKey
        }
    }

    private static func unfoldLines(in text: String) -> [String] {
        var result: [String] = []

        for rawLine in text.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            if line.hasPrefix(" ") || line.hasPrefix("\t") {
                guard let previous = result.popLast() else { continue }
                result.append(previous + String(line.dropFirst()))
            } else {
                result.append(line)
            }
        }

        return result
    }

    private static func extractEvents(from lines: [String]) -> [[String: String]] {
        var events: [[String: String]] = []
        var current: [String: String]?

        for line in lines {
            if line == "BEGIN:VEVENT" {
                current = [:]
                continue
            }

            if line == "END:VEVENT" {
                if let current {
                    events.append(current)
                }
                current = nil
                continue
            }

            guard current != nil, let separator = line.firstIndex(of: ":") else {
                continue
            }

            let rawKey = String(line[..<separator])
            let key = rawKey.components(separatedBy: ";").first ?? rawKey
            let value = String(line[line.index(after: separator)...])
            current?[key] = value
        }

        return events
    }

    private static func parseDate(_ value: String) -> Date? {
        let trimmed = String(value.prefix(8))
        guard trimmed.count == 8,
              let year = Int(trimmed.prefix(4)),
              let month = Int(trimmed.dropFirst(4).prefix(2)),
              let day = Int(trimmed.suffix(2))
        else {
            return nil
        }

        return CalendarMath.calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    private static func holidayKind(from event: [String: String], summary: String) -> HolidayKind {
        let specialDay = event["X-APPLE-SPECIAL-DAY"] ?? ""

        if specialDay == "ALTERNATE-WORKDAY" || summary.contains("（班）") {
            return .workday
        }

        if specialDay == "WORK-HOLIDAY" || summary.contains("（休）") {
            return .holiday
        }

        return .observance
    }

    private static func recurrenceCount(from value: String) -> Int? {
        value
            .components(separatedBy: ";")
            .first { $0.hasPrefix("COUNT=") }
            .flatMap { Int($0.replacingOccurrences(of: "COUNT=", with: "")) }
    }

    private static func expandYearly(start: Date, count: Int, name: String, kind: HolidayKind) -> [Holiday] {
        let components = CalendarMath.calendar.dateComponents([.year, .month, .day], from: start)
        guard let year = components.year,
              let month = components.month,
              let day = components.day
        else {
            return []
        }

        return (0..<count).compactMap { offset in
            guard let date = CalendarMath.calendar.date(from: DateComponents(year: year + offset, month: month, day: day)) else {
                return nil
            }
            return Holiday(dateKey: CalendarMath.dateKey(for: date), name: name, kind: kind)
        }
    }

    private static func expandRange(start: Date, end: Date?, name: String, kind: HolidayKind) -> [Holiday] {
        let exclusiveEnd = end ?? CalendarMath.calendar.date(byAdding: .day, value: 1, to: start) ?? start
        var cursor = start
        var holidays: [Holiday] = []

        while cursor < exclusiveEnd {
            holidays.append(Holiday(dateKey: CalendarMath.dateKey(for: cursor), name: name, kind: kind))
            guard let next = CalendarMath.calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }

        return holidays
    }

    private static func clean(_ summary: String) -> String {
        summary
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "（休）", with: "")
            .replacingOccurrences(of: "（班）", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
