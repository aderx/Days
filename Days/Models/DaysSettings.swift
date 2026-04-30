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

enum PanelReleaseDelay: String, Codable, CaseIterable, Identifiable {
    case immediate
    case seconds15
    case seconds30
    case minutes2

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .immediate:
            return "立即"
        case .seconds15:
            return "15 秒"
        case .seconds30:
            return "30 秒"
        case .minutes2:
            return "2 分钟"
        }
    }

    var detail: String {
        switch self {
        case .immediate:
            return "关闭后立刻释放，占用最低"
        case .seconds15:
            return "短时间复用，兼顾响应和内存"
        case .seconds30:
            return "推荐，频繁查看更顺手"
        case .minutes2:
            return "长时间复用，打开最快"
        }
    }

    var interval: TimeInterval {
        switch self {
        case .immediate:
            return 0
        case .seconds15:
            return 15
        case .seconds30:
            return 30
        case .minutes2:
            return 120
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
    var panelReleaseDelay: PanelReleaseDelay

    static let defaultSourceURL = "https://calendars.icloud.com/holidays/cn_zh.ics/"

    static let defaults = DaysSettings(
        showsIcon: true,
        showsYear: true,
        showsMonth: true,
        showsDay: true,
        showsWeekday: false,
        holidaySourceURL: defaultSourceURL,
        calendarTheme: .classic,
        panelReleaseDelay: .seconds30
    )

    enum CodingKeys: String, CodingKey {
        case showsIcon
        case showsYear
        case showsMonth
        case showsDay
        case showsWeekday
        case holidaySourceURL
        case calendarTheme
        case panelReleaseDelay
    }

    init(
        showsIcon: Bool,
        showsYear: Bool,
        showsMonth: Bool,
        showsDay: Bool,
        showsWeekday: Bool,
        holidaySourceURL: String,
        calendarTheme: CalendarTheme,
        panelReleaseDelay: PanelReleaseDelay
    ) {
        self.showsIcon = showsIcon
        self.showsYear = showsYear
        self.showsMonth = showsMonth
        self.showsDay = showsDay
        self.showsWeekday = showsWeekday
        self.holidaySourceURL = holidaySourceURL
        self.calendarTheme = calendarTheme
        self.panelReleaseDelay = panelReleaseDelay
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
        panelReleaseDelay = try container.decodeIfPresent(PanelReleaseDelay.self, forKey: .panelReleaseDelay) ?? .seconds30
    }
}
