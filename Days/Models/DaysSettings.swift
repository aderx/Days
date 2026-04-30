import Foundation

struct DaysSettings: Codable, Equatable {
    var showsIcon: Bool
    var showsYear: Bool
    var showsMonth: Bool
    var showsDay: Bool
    var showsWeekday: Bool
    var holidaySourceURL: String

    static let defaultSourceURL = "https://calendars.icloud.com/holidays/cn_zh.ics/"

    static let defaults = DaysSettings(
        showsIcon: true,
        showsYear: true,
        showsMonth: true,
        showsDay: true,
        showsWeekday: false,
        holidaySourceURL: defaultSourceURL
    )
}

