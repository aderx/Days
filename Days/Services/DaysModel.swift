import Foundation
import Combine

@MainActor
final class DaysModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var displayedMonth: Date
    @Published var settings: DaysSettings {
        didSet {
            persistSettings()
        }
    }

    let holidayStore: HolidayStore

    private let settingsKey = "Days.settings"
    private var cancellables = Set<AnyCancellable>()

    init(now: Date = Date()) {
        selectedDate = CalendarMath.startOfDay(now)
        displayedMonth = CalendarMath.startOfMonth(for: now)
        holidayStore = HolidayStore()

        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(DaysSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .defaults
        }

        holidayStore.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }

    var menuBarTitle: String {
        formatMenuBarTitle(for: Date())
    }

    var selectedDateTitle: String {
        CalendarMath.chineseFullDate(selectedDate, includeYear: true, includeWeekday: true)
    }

    var selectedYearMonthTitle: String {
        CalendarMath.yearMonthUnitText(for: selectedDate)
    }

    var selectedDaySuffixTitle: String {
        "日 \(CalendarMath.weekdayText(for: selectedDate))"
    }

    var selectedDayNumber: String {
        CalendarMath.dayNumber(for: selectedDate)
    }

    var displayedMonthTitle: String {
        CalendarMath.monthTitle(for: displayedMonth)
    }

    var displayedYearUnitText: String {
        CalendarMath.yearUnitText(for: displayedMonth)
    }

    var displayedMonthUnitText: String {
        CalendarMath.monthUnitText(for: displayedMonth)
    }

    var visibleDays: [DayCell] {
        CalendarMath.makeVisibleDays(for: displayedMonth)
    }

    var selectedHolidays: [Holiday] {
        holidayStore.holidays(on: selectedDate)
    }

    var shouldShowTodayShortcut: Bool {
        !CalendarMath.isSameDay(selectedDate, Date()) ||
        !CalendarMath.calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    func select(_ date: Date) {
        selectedDate = CalendarMath.startOfDay(date)
        displayedMonth = CalendarMath.startOfMonth(for: date)
    }

    func goToPreviousMonth() {
        displayedMonth = CalendarMath.addMonths(-1, to: displayedMonth)
    }

    func goToNextMonth() {
        displayedMonth = CalendarMath.addMonths(1, to: displayedMonth)
    }

    func goToPreviousYear() {
        displayedMonth = CalendarMath.addYears(-1, to: displayedMonth)
    }

    func goToNextYear() {
        displayedMonth = CalendarMath.addYears(1, to: displayedMonth)
    }

    func changeSelectedYear(by value: Int) {
        updateSelectedDate(
            year: CalendarMath.year(for: selectedDate) + value,
            month: CalendarMath.month(for: selectedDate)
        )
    }

    func changeSelectedMonth(by value: Int) {
        let currentYear = CalendarMath.year(for: selectedDate)
        let currentMonth = CalendarMath.month(for: selectedDate)
        var targetYear = currentYear
        var targetMonth = currentMonth + value

        while targetMonth < 1 {
            targetMonth += 12
            targetYear -= 1
        }

        while targetMonth > 12 {
            targetMonth -= 12
            targetYear += 1
        }

        updateSelectedDate(year: targetYear, month: targetMonth)
    }

    func updateSelectedDate(year: Int, month: Int) {
        let nextDate = CalendarMath.clampedDate(
            year: year,
            month: month,
            preferredDay: CalendarMath.day(for: selectedDate)
        )
        selectedDate = CalendarMath.startOfDay(nextDate)
        displayedMonth = CalendarMath.startOfMonth(for: nextDate)
    }

    func goToToday() {
        let today = CalendarMath.startOfDay(Date())
        selectedDate = today
        displayedMonth = CalendarMath.startOfMonth(for: today)
    }

    func syncHolidays() {
        Task {
            await holidayStore.sync(from: settings.holidaySourceURL)
        }
    }

    func holidays(on date: Date) -> [Holiday] {
        holidayStore.holidays(on: date)
    }

    private func formatMenuBarTitle(for date: Date) -> String {
        let components = CalendarMath.calendar.dateComponents([.year, .month, .day], from: date)
        var parts: [String] = []

        if settings.showsYear {
            parts.append(String(format: "%04d年", components.year ?? 0))
        }

        if settings.showsMonth {
            parts.append(String(format: "%02d月", components.month ?? 0))
        }

        if settings.showsDay {
            parts.append(String(format: "%02d日", components.day ?? 0))
        }

        if settings.showsWeekday {
            parts.append(CalendarMath.weekdayText(for: date))
        }

        let title = parts.joined()
        return title.isEmpty ? "Days" : title
    }

    private func persistSettings() {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }
}
