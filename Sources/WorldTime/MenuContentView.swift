import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject private var store: CityStore
    @EnvironmentObject private var launchAtLogin: LaunchAtLogin
    // Observed so the whole popover re-renders when the language changes.
    @EnvironmentObject private var preferences: Preferences
    @State private var isAddingCity = false

    var body: some View {
        Group {
            if isAddingCity {
                AddCityView(isPresented: $isAddingCity)
            } else {
                mainContent
            }
        }
        .frame(width: 340)
        .onAppear { launchAtLogin.refresh() }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ClockRow(title: localCityName, timeZone: .current, isLocal: true)
                .padding(.top, 6)

            Divider().padding(.horizontal, 14)

            if store.cities.isEmpty {
                Text(L("Add up to %d cities to compare times.", CityStore.maxCities))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(store.cities.enumerated()), id: \.element.id) { index, city in
                    ClockRow(
                        title: CityNames.displayName(city.name, timeZoneID: city.timeZoneID),
                        timeZone: city.timeZone,
                        isLocal: false,
                        onRemove: { store.remove(city) },
                        onMoveUp: index > 0 ? { store.move(city, by: -1) } : nil,
                        onMoveDown: index < store.cities.count - 1 ? { store.move(city, by: 1) } : nil
                    )
                }
            }

            HStack {
                Text(L("%1$d of %2$d cities", store.cities.count, CityStore.maxCities))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    isAddingCity = true
                } label: {
                    Label(L("Add City"), systemImage: "plus")
                }
                .disabled(store.isFull)
                .help(store.isFull ? L("Remove a city to add another.") : L("Add City"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()

            SettingsSection()
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            Divider()

            CalendarView()
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            Divider()

            HStack {
                Spacer()
                Button(L("Quit World Time")) { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private var localCityName: String {
        let id = TimeZone.current.identifier
        return CityNames.displayName(CityNames.identifierCityName(id), timeZoneID: id)
    }
}
