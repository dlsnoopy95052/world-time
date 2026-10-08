import Foundation

/// A searchable city → time zone mapping.
struct CityEntry: Identifiable, Hashable, Sendable {
    let name: String
    let region: String
    let timeZoneID: String

    var id: String { "\(name)|\(timeZoneID)" }
}

enum CityCatalog {
    /// Well-known cities that don't have their own IANA identifier.
    private static let aliases: [CityEntry] = [
        ("San Francisco", "United States", "America/Los_Angeles"),
        ("Seattle", "United States", "America/Los_Angeles"),
        ("San Diego", "United States", "America/Los_Angeles"),
        ("Las Vegas", "United States", "America/Los_Angeles"),
        ("Portland", "United States", "America/Los_Angeles"),
        ("Salt Lake City", "United States", "America/Denver"),
        ("Dallas", "United States", "America/Chicago"),
        ("Houston", "United States", "America/Chicago"),
        ("Austin", "United States", "America/Chicago"),
        ("Minneapolis", "United States", "America/Chicago"),
        ("Washington, D.C.", "United States", "America/New_York"),
        ("Boston", "United States", "America/New_York"),
        ("Miami", "United States", "America/New_York"),
        ("Atlanta", "United States", "America/New_York"),
        ("Philadelphia", "United States", "America/New_York"),
        ("Ottawa", "Canada", "America/Toronto"),
        ("Montreal", "Canada", "America/Toronto"),
        ("Calgary", "Canada", "America/Edmonton"),
        ("Rio de Janeiro", "Brazil", "America/Sao_Paulo"),
        ("Munich", "Germany", "Europe/Berlin"),
        ("Frankfurt", "Germany", "Europe/Berlin"),
        ("Hamburg", "Germany", "Europe/Berlin"),
        ("Milan", "Italy", "Europe/Rome"),
        ("Barcelona", "Spain", "Europe/Madrid"),
        ("Geneva", "Switzerland", "Europe/Zurich"),
        ("Manchester", "United Kingdom", "Europe/London"),
        ("Edinburgh", "United Kingdom", "Europe/London"),
        ("Tel Aviv", "Israel", "Asia/Jerusalem"),
        ("Abu Dhabi", "United Arab Emirates", "Asia/Dubai"),
        ("Mumbai", "India", "Asia/Kolkata"),
        ("New Delhi", "India", "Asia/Kolkata"),
        ("Bangalore", "India", "Asia/Kolkata"),
        ("Hyderabad", "India", "Asia/Kolkata"),
        ("Beijing", "China", "Asia/Shanghai"),
        ("Shenzhen", "China", "Asia/Shanghai"),
        ("Guangzhou", "China", "Asia/Shanghai"),
        ("Hangzhou", "China", "Asia/Shanghai"),
        ("Hanoi", "Vietnam", "Asia/Bangkok"),
        ("Osaka", "Japan", "Asia/Tokyo"),
        ("Kyoto", "Japan", "Asia/Tokyo"),
        ("Busan", "South Korea", "Asia/Seoul"),
        ("Canberra", "Australia", "Australia/Sydney"),
        ("Wellington", "New Zealand", "Pacific/Auckland"),
    ].map { CityEntry(name: $0.0, region: $0.1, timeZoneID: $0.2) }

    static let all: [CityEntry] = {
        let fromIdentifiers = TimeZone.knownTimeZoneIdentifiers.compactMap { id -> CityEntry? in
            let parts = id.split(separator: "/")
            guard parts.count >= 2, parts[0] != "Etc" else { return nil }
            let name = parts.last!.replacingOccurrences(of: "_", with: " ")
            let region = parts.dropLast().joined(separator: " / ").replacingOccurrences(of: "_", with: " ")
            return CityEntry(name: name, region: region, timeZoneID: id)
        }
        let utc = CityEntry(name: "UTC", region: "Coordinated Universal Time", timeZoneID: "UTC")
        let valid = (aliases + fromIdentifiers).filter { TimeZone(identifier: $0.timeZoneID) != nil }
        return ([utc] + valid).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }()

    /// Searches city names, regions, zone identifiers, and zone names like "Pacific Time" or "CET".
    static func search(_ query: String) -> [CityEntry] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return all }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

        var prefixMatches: [CityEntry] = []
        var otherMatches: [CityEntry] = []
        for entry in all {
            if entry.name.range(of: query, options: options.union(.anchored)) != nil {
                prefixMatches.append(entry)
            } else if searchIndex[entry.id, default: entry.name].range(of: query, options: options) != nil {
                otherMatches.append(entry)
            }
        }
        return prefixMatches + otherMatches
    }

    private static let searchIndex: [String: String] = Dictionary(all.map { entry in
        let zone = TimeZone(identifier: entry.timeZoneID)
        let text = [
            entry.name,
            entry.region,
            entry.timeZoneID,
            zone?.localizedName(for: .generic, locale: .current) ?? "",
            zone?.localizedName(for: .shortStandard, locale: .current) ?? "",
            zone?.localizedName(for: .shortDaylightSaving, locale: .current) ?? "",
        ].joined(separator: " ")
        return (entry.id, text)
    }, uniquingKeysWith: { first, _ in first })
}
