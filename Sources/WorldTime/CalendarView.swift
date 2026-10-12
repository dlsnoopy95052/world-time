import SwiftUI

/// A month grid in the Mac's local time zone with today highlighted and previous/next navigation.
struct CalendarView: View {
    @EnvironmentObject private var clock: Clock
    // Observed so the month and weekday names re-render when the language changes.
    @EnvironmentObject private var preferences: Preferences

    /// Any date within the month being shown.
    @State private var month = Date()

    private var calendar: Calendar { .autoupdatingCurrent }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let today = clock.now
        let isCurrentMonth = calendar.isDate(month, equalTo: today, toGranularity: .month)

        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text(Formatters.string(month, template: "yMMMM", in: calendar.timeZone))
                    .font(.headline)
                Spacer()
                if !isCurrentMonth {
                    Button(L("Today")) { month = today }
                        .buttonStyle(.link)
                        .font(.caption)
                }
                Button { shift(by: -1) } label: { Image(systemName: "chevron.left") }
                    .help(L("Previous month"))
                Button { shift(by: 1) } label: { Image(systemName: "chevron.right") }
                    .help(L("Next month"))
            }
            .buttonStyle(.borderless)

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date, isToday: calendar.isDate(date, inSameDayAs: today))
                    } else {
                        Color.clear.frame(height: 26)
                    }
                }
            }
        }
        // Start on the current month each time the popover opens.
        .onAppear { month = clock.now }
    }

    private func dayCell(_ date: Date, isToday: Bool) -> some View {
        Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 12, weight: isToday ? .bold : .regular))
            .monospacedDigit()
            .foregroundStyle(isToday ? Color.white : Color.primary)
            .frame(width: 26, height: 26)
            .background(Circle().fill(isToday ? Color.accentColor : .clear))
            .frame(maxWidth: .infinity)
    }

    private func shift(by months: Int) {
        month = calendar.date(byAdding: .month, value: months, to: month) ?? month
    }

    /// Single-letter weekday names starting from the locale's first weekday.
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Localization.locale
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? []
        guard symbols.count == 7 else { return [] }
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Leading blanks followed by every day of the displayed month.
    private var cells: [Date?] {
        guard let start = calendar.dateInterval(of: .month, for: month)?.start,
              let days = calendar.range(of: .day, in: .month, for: start) else { return [] }
        let weekday = calendar.component(.weekday, from: start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading)
            + days.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }
}
