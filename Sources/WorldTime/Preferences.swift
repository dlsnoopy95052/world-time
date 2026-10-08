import Foundation

/// User settings, persisted in UserDefaults.
@MainActor
final class Preferences: ObservableObject {
    private enum Key {
        static let use24Hour = "use24Hour"
        static let showSeconds = "showSeconds"
        static let showDayInMenuBar = "showDayInMenuBar"
        static let showDateInMenuBar = "showDateInMenuBar"
        static let language = "language"
        static let showLunarInMenuBar = "showLunarInMenuBar"
    }

    private let defaults: UserDefaults

    @Published var use24Hour: Bool { didSet { defaults.set(use24Hour, forKey: Key.use24Hour) } }
    @Published var showSeconds: Bool { didSet { defaults.set(showSeconds, forKey: Key.showSeconds) } }
    @Published var showDayInMenuBar: Bool { didSet { defaults.set(showDayInMenuBar, forKey: Key.showDayInMenuBar) } }
    @Published var showDateInMenuBar: Bool { didSet { defaults.set(showDateInMenuBar, forKey: Key.showDateInMenuBar) } }
    @Published var showLunarInMenuBar: Bool { didSet { defaults.set(showLunarInMenuBar, forKey: Key.showLunarInMenuBar) } }
    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Key.language)
            Localization.apply(language)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Default the clock style to whatever the user's locale prefers.
        let localePrefers24h = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?
            .contains("H") ?? false
        use24Hour = defaults.object(forKey: Key.use24Hour) as? Bool ?? localePrefers24h
        showSeconds = defaults.object(forKey: Key.showSeconds) as? Bool ?? false
        showDayInMenuBar = defaults.object(forKey: Key.showDayInMenuBar) as? Bool ?? true
        showDateInMenuBar = defaults.object(forKey: Key.showDateInMenuBar) as? Bool ?? true
        showLunarInMenuBar = defaults.object(forKey: Key.showLunarInMenuBar) as? Bool ?? false
        language = defaults.string(forKey: Key.language).flatMap(AppLanguage.init(rawValue:)) ?? .system
        Localization.apply(language)
    }
}
