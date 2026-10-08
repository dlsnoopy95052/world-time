import SwiftUI

struct SettingsSection: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var launchAtLogin: LaunchAtLogin

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker(L("Clock"), selection: $preferences.use24Hour) {
                Text(L("12-hour")).tag(false)
                Text(L("24-hour")).tag(true)
            }
            .pickerStyle(.segmented)

            Picker(L("Language"), selection: $preferences.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeName).tag(language)
                }
            }

            Toggle(L("Show seconds"), isOn: $preferences.showSeconds)
            Toggle(L("Show day in menu bar"), isOn: $preferences.showDayInMenuBar)
            Toggle(L("Show date in menu bar"), isOn: $preferences.showDateInMenuBar)
            if Localization.isChinese {
                Toggle(L("Show lunar date in menu bar"), isOn: $preferences.showLunarInMenuBar)
            }
            Toggle(L("Launch at login"), isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))

            if let problem = launchAtLogin.problem {
                Text(problem.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(L("Open Login Items Settings…")) { launchAtLogin.openLoginItemsSettings() }
                    .controlSize(.small)
            }
        }
        .toggleStyle(.checkbox)
    }
}
