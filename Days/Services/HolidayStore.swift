import Foundation

@MainActor
final class HolidayStore: ObservableObject {
    enum SyncState: Equatable {
        case idle
        case syncing
        case success(Date)
        case failed(String)

        var label: String {
            switch self {
            case .idle:
                return "[READY]"
            case .syncing:
                return "[SYNCING]"
            case .success:
                return "[SYNCED]"
            case .failed:
                return "[ERROR]"
            }
        }
    }

    @Published private(set) var holidays: [Holiday] = []
    @Published private(set) var syncState: SyncState = .idle
    @Published private(set) var lastSyncedAt: Date?

    private let cacheURL: URL
    private let lastSyncedKey = "Days.lastSyncedAt"

    init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let daysDirectory = supportDirectory.appendingPathComponent("Days", isDirectory: true)
        try? FileManager.default.createDirectory(at: daysDirectory, withIntermediateDirectories: true)
        cacheURL = daysDirectory.appendingPathComponent("Holidays.json")

        if let date = UserDefaults.standard.object(forKey: lastSyncedKey) as? Date {
            lastSyncedAt = date
        }

        load()
    }

    func holidays(on date: Date) -> [Holiday] {
        let key = CalendarMath.dateKey(for: date)
        return holidays.filter { $0.dateKey == key }
    }

    func sync(from sourceURL: String) async {
        guard let url = URL(string: sourceURL) else {
            syncState = .failed("INVALID URL")
            return
        }

        syncState = .syncing

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let text = String(data: data, encoding: .utf8) else {
                syncState = .failed("BAD DATA")
                return
            }

            let parsed = ICSHolidayParser.parse(text)
            guard !parsed.isEmpty else {
                syncState = .failed("EMPTY SOURCE")
                return
            }

            holidays = parsed
            try save(parsed)
            let now = Date()
            lastSyncedAt = now
            UserDefaults.standard.set(now, forKey: lastSyncedKey)
            syncState = .success(now)
        } catch {
            syncState = .failed(error.localizedDescription.uppercased())
        }
    }

    private func load() {
        if let cached = loadCache(), !cached.isEmpty {
            holidays = cached
            return
        }

        holidays = loadSeed()
    }

    private func loadCache() -> [Holiday]? {
        guard let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }
        return try? JSONDecoder().decode([Holiday].self, from: data)
    }

    private func loadSeed() -> [Holiday] {
        guard let url = Bundle.main.url(forResource: "SeedHolidays", withExtension: "ics"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return []
        }
        return ICSHolidayParser.parse(text)
    }

    private func save(_ holidays: [Holiday]) throws {
        let data = try JSONEncoder().encode(holidays)
        try data.write(to: cacheURL, options: [.atomic])
    }
}

