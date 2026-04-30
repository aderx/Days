import Foundation

enum CalendarTheme: String, Codable, CaseIterable, Identifiable {
    case classic
    case soft

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic:
            return "经典"
        case .soft:
            return "清透"
        }
    }
}

struct DaysSettings: Codable, Equatable {
    var showsIcon: Bool
    var showsYear: Bool
    var showsMonth: Bool
    var showsDay: Bool
    var showsWeekday: Bool
    var holidaySourceURL: String
    var calendarTheme: CalendarTheme

    static let defaultSourceURL = "https://calendars.icloud.com/holidays/cn_zh.ics/"

    static let defaults = DaysSettings(
        showsIcon: true,
        showsYear: true,
        showsMonth: true,
        showsDay: true,
        showsWeekday: false,
        holidaySourceURL: defaultSourceURL,
        calendarTheme: .classic
    )

    enum CodingKeys: String, CodingKey {
        case showsIcon
        case showsYear
        case showsMonth
        case showsDay
        case showsWeekday
        case holidaySourceURL
        case calendarTheme
    }

    init(
        showsIcon: Bool,
        showsYear: Bool,
        showsMonth: Bool,
        showsDay: Bool,
        showsWeekday: Bool,
        holidaySourceURL: String,
        calendarTheme: CalendarTheme
    ) {
        self.showsIcon = showsIcon
        self.showsYear = showsYear
        self.showsMonth = showsMonth
        self.showsDay = showsDay
        self.showsWeekday = showsWeekday
        self.holidaySourceURL = holidaySourceURL
        self.calendarTheme = calendarTheme
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showsIcon = try container.decode(Bool.self, forKey: .showsIcon)
        showsYear = try container.decode(Bool.self, forKey: .showsYear)
        showsMonth = try container.decode(Bool.self, forKey: .showsMonth)
        showsDay = try container.decode(Bool.self, forKey: .showsDay)
        showsWeekday = try container.decode(Bool.self, forKey: .showsWeekday)
        holidaySourceURL = try container.decode(String.self, forKey: .holidaySourceURL)
        calendarTheme = try container.decodeIfPresent(CalendarTheme.self, forKey: .calendarTheme) ?? .classic
    }
}
