import Foundation

/// A city the user added. Stored by IANA time zone identifier (e.g. "Europe/London") rather than
/// a fixed UTC offset, so daylight-saving rules always come from the system's time zone database.
struct SavedCity: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var timeZoneID: String

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .gmt }
}

@MainActor
final class CityStore: ObservableObject {
    static let maxCities = 5
    private static let defaultsKey = "savedCities"

    private let defaults: UserDefaults

    @Published private(set) var cities: [SavedCity] {
        didSet { save() }
    }

    var isFull: Bool { cities.count >= Self.maxCities }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([SavedCity].self, from: data) {
            cities = decoded
        } else {
            cities = []
        }
    }

    func contains(_ entry: CityEntry) -> Bool {
        cities.contains { $0.name == entry.name && $0.timeZoneID == entry.timeZoneID }
    }

    func add(_ entry: CityEntry) {
        guard !isFull, !contains(entry) else { return }
        cities.append(SavedCity(name: entry.name, timeZoneID: entry.timeZoneID))
    }

    func remove(_ city: SavedCity) {
        cities.removeAll { $0.id == city.id }
    }

    func move(_ city: SavedCity, by offset: Int) {
        guard let index = cities.firstIndex(of: city) else { return }
        let target = index + offset
        guard cities.indices.contains(target) else { return }
        cities.swapAt(index, target)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(cities) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
