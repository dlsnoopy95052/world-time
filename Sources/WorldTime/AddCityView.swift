import SwiftUI

struct AddCityView: View {
    @Binding var isPresented: Bool

    @EnvironmentObject private var store: CityStore
    @EnvironmentObject private var clock: Clock
    @EnvironmentObject private var preferences: Preferences
    @State private var query = ""
    @State private var hoveredID: String?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .help(L("Back"))

                TextField(L("Search city, country or time zone"), text: $query)
                    .textFieldStyle(.roundedBorder)
                    .focused($isSearchFocused)
                    .onSubmit { if let first = results.first { add(first) } }
            }
            .padding(10)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(results) { entry in
                        resultRow(entry)
                    }
                }
            }
            .frame(height: 340)
        }
        .onAppear { isSearchFocused = true }
        .onExitCommand { isPresented = false }
    }

    private var results: [CityEntry] {
        CityCatalog.search(query)
    }

    private func resultRow(_ entry: CityEntry) -> some View {
        let zone = TimeZone(identifier: entry.timeZoneID) ?? .gmt
        let alreadyAdded = store.contains(entry)
        return Button {
            add(entry)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(CityCatalog.displayName(of: entry))
                    Text("\(CityCatalog.regionName(of: entry)) · \(Formatters.abbreviation(of: zone, at: clock.now))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if alreadyAdded {
                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                } else {
                    Text(Formatters.time(clock.now, in: zone, preferences: preferences))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(hoveredID == entry.id ? Color.accentColor.opacity(0.15) : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(alreadyAdded)
        .onHover { hoveredID = $0 ? entry.id : (hoveredID == entry.id ? nil : hoveredID) }
    }

    private func add(_ entry: CityEntry) {
        store.add(entry)
        isPresented = false
    }
}
