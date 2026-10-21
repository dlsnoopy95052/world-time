import AppKit
import SwiftUI

@main
struct WorldTimeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var preferences: Preferences
    @StateObject private var clock: Clock
    @StateObject private var store = CityStore()
    @StateObject private var launchAtLogin = LaunchAtLogin()

    init() {
        let preferences = Preferences()
        _preferences = StateObject(wrappedValue: preferences)
        _clock = StateObject(wrappedValue: Clock(preferences: preferences))
        // Menu-bar only: no Dock icon (also set via LSUIElement when bundled).
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(preferences)
                .environmentObject(clock)
                .environmentObject(store)
                .environmentObject(launchAtLogin)
        } label: {
            Text(menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }

    /// e.g. "Thu, Oct 8  2:32 PM", or "10月8日 · 八月廿八  14:32" with the lunar date
    private var menuBarTitle: String {
        let local = TimeZone.current
        var dateTemplate = ""
        if preferences.showDayInMenuBar { dateTemplate += "EEE" }
        if preferences.showDateInMenuBar { dateTemplate += "MMMd" }
        var dates: [String] = []
        if !dateTemplate.isEmpty {
            dates.append(Formatters.string(clock.now, template: dateTemplate, in: local))
        }
        if Localization.isChinese && preferences.showLunarInMenuBar {
            dates.append(Formatters.lunarDate(clock.now, in: local, includeYear: false))
        }
        // A dot between the local and lunar dates keeps them from reading as one phrase.
        var parts: [String] = []
        if !dates.isEmpty { parts.append(dates.joined(separator: " · ")) }
        parts.append(Formatters.time(clock.now, in: local, preferences: preferences))
        return parts.joined(separator: "  ")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Opening the app again (from Launchpad, Spotlight or Finder) while it's running has no
    /// window to show, so open the menu bar popover instead.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItemButton()?.performClick(nil)
        return false
    }

    private func statusItemButton() -> NSStatusBarButton? {
        func find(in view: NSView?) -> NSStatusBarButton? {
            guard let view else { return nil }
            if let button = view as? NSStatusBarButton { return button }
            return view.subviews.lazy.compactMap { find(in: $0) }.first
        }
        return NSApp.windows.lazy.compactMap { find(in: $0.contentView) }.first
    }
}
