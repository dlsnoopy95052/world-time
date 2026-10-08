import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    /// Each language is named in its own script so it's recognizable whatever the current language.
    @MainActor
    var nativeName: String {
        switch self {
        case .system: L("System")
        case .english: "English"
        case .traditionalChinese: "繁體中文"
        }
    }
}

/// The app's display language. Strings come from Resources/<lang>.lproj, and the matching locale
/// drives date, weekday, AM/PM, city and country names.
@MainActor
enum Localization {
    static let supported = ["en", "zh-Hant"]

    private(set) static var languageCode = "en"
    private(set) static var locale = Locale.current
    private static var bundle: Bundle?

    static func apply(_ language: AppLanguage) {
        if language == .system {
            // Honors macOS's per-app language setting as well as the system language list.
            languageCode = Bundle.preferredLocalizations(from: supported, forPreferences: Locale.preferredLanguages)
                .first ?? "en"
        } else {
            languageCode = language.rawValue
        }
        // Keep the user's region so formats like day/month order still follow their settings.
        let region = Locale.current.region?.identifier
        locale = Locale(identifier: region.map { "\(languageCode)-\($0)" } ?? languageCode)
        bundle = Bundle.main.path(forResource: languageCode, ofType: "lproj").flatMap(Bundle.init(path:))
    }

    static func string(_ key: String, table: String? = nil) -> String {
        bundle?.localizedString(forKey: key, value: key, table: table) ?? key
    }

    static var isChinese: Bool { languageCode.hasPrefix("zh") }
}

/// Looks up `key` (the English text) in the current language, formatting any arguments.
@MainActor
func L(_ key: String, _ arguments: CVarArg...) -> String {
    let format = Localization.string(key)
    return arguments.isEmpty ? format : String(format: format, locale: Localization.locale, arguments: arguments)
}

/// Localized city and region names.
@MainActor
enum CityNames {
    private static var exemplarCache: [String: String] = [:]

    /// `englishName` is the stored name; cities without their own time zone ID (e.g. San Francisco)
    /// are translated via Cities.strings, the rest via the system's ICU exemplar city names.
    static func displayName(_ englishName: String, timeZoneID: String) -> String {
        guard Localization.isChinese else { return englishName }
        let translated = Localization.string(englishName, table: "Cities")
        if translated != englishName { return translated }
        guard englishName == identifierCityName(timeZoneID), !linkedZoneIDs.contains(timeZoneID) else {
            return englishName
        }
        return exemplarCity(timeZoneID, locale: Localization.locale) ?? englishName
    }

    /// Legacy zone IDs that ICU treats as aliases of another listed city (e.g. Asia/Chongqing and
    /// Asia/Harbin are both "Shanghai"), so their exemplar name would be the wrong city.
    private static let linkedZoneIDs: Set<String> = {
        let english = Locale(identifier: "en")
        let ids = TimeZone.knownTimeZoneIdentifiers.filter { $0.contains("/") }
        let ownNames = Set(ids.map(identifierCityName))
        return Set(ids.filter { id in
            guard let exemplar = exemplarCity(id, locale: english) else { return false }
            return exemplar != identifierCityName(id) && ownNames.contains(exemplar)
        })
    }()

    /// Country name for alias cities, otherwise the zone's name, e.g. "Japan Standard Time" / "日本標準時間".
    static func regionName(countryCode: String?, timeZoneID: String) -> String {
        if let countryCode, let country = Localization.locale.localizedString(forRegionCode: countryCode) {
            return country
        }
        if timeZoneID == "UTC" { return L("Coordinated Universal Time") }
        return TimeZone(identifier: timeZoneID)?.localizedName(for: .generic, locale: Localization.locale) ?? timeZoneID
    }

    /// "America/Los_Angeles" → "Los Angeles".
    static func identifierCityName(_ timeZoneID: String) -> String {
        timeZoneID.split(separator: "/").last.map { $0.replacingOccurrences(of: "_", with: " ") } ?? timeZoneID
    }

    static func exemplarCity(_ timeZoneID: String, locale: Locale) -> String? {
        guard timeZoneID != "UTC", timeZoneID.contains("/") else { return nil }
        let key = "\(locale.identifier)|\(timeZoneID)"
        if let cached = exemplarCache[key] { return cached }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: timeZoneID)
        formatter.dateFormat = "VVV"
        let name = formatter.string(from: Date())
        exemplarCache[key] = name
        return name
    }
}
