import Foundation

struct DayCell: Identifiable {
    let date: Date
    let isInDisplayedMonth: Bool

    var id: Date { date }
}

