import Foundation

enum HolidayKind: String, Codable {
    case holiday
    case workday
    case observance

    var shortLabel: String {
        switch self {
        case .holiday:
            return "休"
        case .workday:
            return "班"
        case .observance:
            return "节"
        }
    }
}

struct Holiday: Identifiable, Codable, Hashable {
    let dateKey: String
    let name: String
    let kind: HolidayKind

    var id: String {
        "\(dateKey)-\(name)-\(kind.rawValue)"
    }
}

