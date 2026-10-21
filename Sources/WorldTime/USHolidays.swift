import Foundation

/// US federal holidays. Fixed-date holidays that land on a weekend are also marked on the
/// weekday they are observed (Saturday → Friday, Sunday → Monday).
@MainActor
enum USHolidays {
    /// Localized holiday names keyed by "year-month-day" for `year`.
    static func names(in year: Int) -> [String: String] {
        var result: [String: String] = [:]
        let calendar = Calendar(identifier: .gregorian)

        func add(_ month: Int, _ day: Int, _ name: String) {
            result["\(year)-\(month)-\(day)"] = name
        }

        func fixed(_ month: Int, _ day: Int, _ name: String) {
            add(month, day, L(name))
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return }
            let weekday = calendar.component(.weekday, from: date)
            let shift = weekday == 7 ? -1 : weekday == 1 ? 1 : 0
            guard shift != 0, let observed = calendar.date(byAdding: .day, value: shift, to: date) else { return }
            let parts = calendar.dateComponents([.year, .month, .day], from: observed)
            // An observed date can spill into the neighboring year (e.g. Jan 1 on a Saturday).
            if parts.year == year {
                add(parts.month!, parts.day!, L("%@ (observed)", L(name)))
            }
        }

        /// The `n`th `weekday` (1 = Sunday) of `month`; `n == -1` means the last one.
        func nth(_ n: Int, _ weekday: Int, of month: Int, _ name: String) {
            if n > 0 {
                guard let day = calendar.date(from: DateComponents(year: year, month: month, weekday: weekday, weekdayOrdinal: n)) else { return }
                add(month, calendar.component(.day, from: day), L(name))
            } else {
                guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                      let count = calendar.range(of: .day, in: .month, for: first)?.count else { return }
                for day in stride(from: count, through: 1, by: -1) {
                    let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                    if calendar.component(.weekday, from: date) == weekday {
                        add(month, day, L(name))
                        return
                    }
                }
            }
        }

        fixed(1, 1, "New Year's Day")
        nth(3, 2, of: 1, "Martin Luther King Jr. Day")
        nth(3, 2, of: 2, "Presidents' Day")
        nth(-1, 2, of: 5, "Memorial Day")
        fixed(6, 19, "Juneteenth")
        fixed(7, 4, "Independence Day")
        nth(1, 2, of: 9, "Labor Day")
        nth(2, 2, of: 10, "Columbus Day")
        fixed(11, 11, "Veterans Day")
        nth(4, 5, of: 11, "Thanksgiving")
        fixed(12, 25, "Christmas Day")
        return result
    }
}
