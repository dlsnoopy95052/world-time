import SwiftUI

struct SettingsSection: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var launchAtLogin: LaunchAtLogin

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Clock", selection: $preferences.use24Hour) {
                Text("12-hour").tag(false)
                Text("24-hour").tag(true)
            }
            .pickerStyle(.segmented)

            Toggle("Show seconds", isOn: $preferences.showSeconds)
            Toggle("Show day in menu bar", isOn: $preferences.showDayInMenuBar)
            Toggle("Show date in menu bar", isOn: $preferences.showDateInMenuBar)
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))

            if let message = launchAtLogin.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Login Items Settings…") { launchAtLogin.openLoginItemsSettings() }
                    .controlSize(.small)
            }
        }
        .toggleStyle(.checkbox)
    }
}
