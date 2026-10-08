import Foundation

/// A searchable city → time zone mapping. `name` is English; it's translated for display.
struct CityEntry: Identifiable, Hashable, Sendable {
    let name: String
    /// ISO country code for cities that share another city's zone (e.g. "US" for San Francisco).
    let countryCode: String?
    let timeZoneID: String

    var id: String { "\(name)|\(timeZoneID)" }
}

@MainActor
enum CityCatalog {
    /// Well-known cities that don't have their own IANA identifier.
    /// Their Chinese names live in Resources/zh-Hant.lproj/Cities.strings.
    private static let aliases: [CityEntry] = [
        ("San Francisco", "US", "America/Los_Angeles"),
        ("Seattle", "US", "America/Los_Angeles"),
        ("San Diego", "US", "America/Los_Angeles"),
        ("Las Vegas", "US", "America/Los_Angeles"),
        ("Portland", "US", "America/Los_Angeles"),
        ("Salt Lake City", "US", "America/Denver"),
        ("Dallas", "US", "America/Chicago"),
        ("Houston", "US", "America/Chicago"),
        ("Austin", "US", "America/Chicago"),
        ("Minneapolis", "US", "America/Chicago"),
        ("Washington, D.C.", "US", "America/New_York"),
        ("Boston", "US", "America/New_York"),
        ("Miami", "US", "America/New_York"),
        ("Atlanta", "US", "America/New_York"),
        ("Philadelphia", "US", "America/New_York"),
        ("Ottawa", "CA", "America/Toronto"),
        ("Calgary", "CA", "America/Edmonton"),
        ("Rio de Janeiro", "BR", "America/Sao_Paulo"),
        ("Munich", "DE", "Europe/Berlin"),
        ("Frankfurt", "DE", "Europe/Berlin"),
        ("Hamburg", "DE", "Europe/Berlin"),
        ("Milan", "IT", "Europe/Rome"),
        ("Barcelona", "ES", "Europe/Madrid"),
        ("Geneva", "CH", "Europe/Zurich"),
        ("Manchester", "GB", "Europe/London"),
        ("Edinburgh", "GB", "Europe/London"),
        ("Tel Aviv", "IL", "Asia/Jerusalem"),
        ("Abu Dhabi", "AE", "Asia/Dubai"),
        ("Mumbai", "IN", "Asia/Kolkata"),
        ("New Delhi", "IN", "Asia/Kolkata"),
        ("Bangalore", "IN", "Asia/Kolkata"),
        ("Hyderabad", "IN", "Asia/Kolkata"),
        ("Beijing", "CN", "Asia/Shanghai"),
        ("Shenzhen", "CN", "Asia/Shanghai"),
        ("Guangzhou", "CN", "Asia/Shanghai"),
        ("Hangzhou", "CN", "Asia/Shanghai"),
        ("Kaohsiung", "TW", "Asia/Taipei"),
        ("Taichung", "TW", "Asia/Taipei"),
        ("Tainan", "TW", "Asia/Taipei"),
        ("Hanoi", "VN", "Asia/Bangkok"),
        ("Osaka", "JP", "Asia/Tokyo"),
        ("Kyoto", "JP", "Asia/Tokyo"),
        ("Busan", "KR", "Asia/Seoul"),
        ("Canberra", "AU", "Australia/Sydney"),
        ("Wellington", "NZ", "Pacific/Auckland"),
    ].map { CityEntry(name: $0.0, countryCode: $0.1, timeZoneID: $0.2) }

    /// Outdated spellings of cities the system also lists under their current name (Kyiv, Yangon, …).
    private static let outdatedSpellings: Set<String> = [
        "Europe/Kiev", "Asia/Rangoon", "Asia/Katmandu", "America/Godthab", "Pacific/Truk", "Pacific/Ponape",
        "Asia/Calcutta", "Asia/Saigon", "Atlantic/Faeroe",
    ]

    static let all: [CityEntry] = {
        let fromIdentifiers = TimeZone.knownTimeZoneIdentifiers.compactMap { id -> CityEntry? in
            let parts = id.split(separator: "/")
            guard parts.count >= 2, parts[0] != "Etc", !outdatedSpellings.contains(id) else { return nil }
            return CityEntry(name: CityNames.identifierCityName(id), countryCode: nil, timeZoneID: id)
        }
        let utc = CityEntry(name: "UTC", countryCode: nil, timeZoneID: "UTC")
        // Skip an alias once the system lists that city under its own zone ID.
        let identifierNames = Set(fromIdentifiers.map(\.name))
        let extraCities = aliases.filter { !identifierNames.contains($0.name) }
        return [utc] + (extraCities + fromIdentifiers).filter { TimeZone(identifier: $0.timeZoneID) != nil }
    }()

    private static var sortedCache: [String: [CityEntry]] = [:]

    /// All cities, sorted by their name in the current language.
    private static var sorted: [CityEntry] {
        let language = Localization.languageCode
        if let cached = sortedCache[language] { return cached }
        let locale = Localization.locale
        let names = Dictionary(all.map { ($0.id, displayName(of: $0)) }, uniquingKeysWith: { a, _ in a })
        let result = all.sorted {
            names[$0.id]!.compare(names[$1.id]!, options: [.caseInsensitive], locale: locale) == .orderedAscending
        }
        sortedCache[language] = result
        return result
    }

    static func displayName(of entry: CityEntry) -> String {
        CityNames.displayName(entry.name, timeZoneID: entry.timeZoneID)
    }

    static func regionName(of entry: CityEntry) -> String {
        CityNames.regionName(countryCode: entry.countryCode, timeZoneID: entry.timeZoneID)
    }

    /// Searches city, country and zone names in both English and Chinese, plus zone IDs and
    /// abbreviations, so "東京", "tokyo", "日本" and "JST" all find Tokyo.
    static func search(_ query: String) -> [CityEntry] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return sorted }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]

        var prefixMatches: [CityEntry] = []
        var otherMatches: [CityEntry] = []
        for entry in sorted {
            let names = searchIndex[entry.id] ?? SearchText(names: [entry.name], other: "")
            if names.names.contains(where: { $0.range(of: query, options: options.union(.anchored)) != nil }) {
                prefixMatches.append(entry)
            } else if names.all.range(of: query, options: options) != nil {
                otherMatches.append(entry)
            }
        }
        return prefixMatches + otherMatches
    }

    private struct SearchText {
        let names: [String]
        let other: String
        var all: String { (names + [other]).joined(separator: " ") }
    }

    private static let searchIndex: [String: SearchText] = {
        let english = Locale(identifier: "en")
        let chinese = Locale(identifier: "zh-Hant-TW")
        let chineseCities = Bundle.main.path(forResource: "zh-Hant", ofType: "lproj").flatMap(Bundle.init(path:))

        return Dictionary(all.map { entry in
            let zone = TimeZone(identifier: entry.timeZoneID)
            var names = [entry.name]
            if let translated = chineseCities?.localizedString(forKey: entry.name, value: nil, table: "Cities"),
               translated != entry.name {
                names.append(translated)
            } else if entry.countryCode == nil, let exemplar = CityNames.exemplarCity(entry.timeZoneID, locale: chinese) {
                names.append(exemplar)
            }
            var other = [entry.timeZoneID]
            if let code = entry.countryCode {
                other += [english, chinese].compactMap { $0.localizedString(forRegionCode: code) }
            }
            for locale in [english, chinese] {
                other += [zone?.localizedName(for: .generic, locale: locale),
                          zone?.localizedName(for: .standard, locale: locale)].compactMap { $0 }
            }
            other += [zone?.localizedName(for: .shortStandard, locale: english),
                      zone?.localizedName(for: .shortDaylightSaving, locale: english)].compactMap { $0 }
            return (entry.id, SearchText(names: names, other: other.joined(separator: " ")))
        }, uniquingKeysWith: { first, _ in first })
    }()
}
