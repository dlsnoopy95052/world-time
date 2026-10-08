import Foundation

/// Cached, time-zone-aware date formatting helpers.
@MainActor
enum Formatters {
    private static var cache: [String: DateFormatter] = [:]

    static func reset() {
        cache.removeAll()
    }

    /// Formats `date` in `timeZone` using a localized skeleton such as "EEEMMMd" or "hmma".
    static func string(_ date: Date, template: String, in timeZone: TimeZone) -> String {
        let locale = Localization.locale
        let key = "\(locale.identifier)|\(timeZone.identifier)|\(template)"
        if let formatter = cache[key] {
            return formatter.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        cache[key] = formatter
        return formatter.string(from: date)
    }

    /// Chinese lunar date in `timeZone`, e.g. "丙午（馬）年八月廿八" or, without the year, "八月廿八".
    /// Month names come from the system's Chinese calendar, which handles leap months (閏六月).
    static func lunarDate(_ date: Date, in timeZone: TimeZone, includeYear: Bool = true) -> String {
        let key = "lunar|\(timeZone.identifier)"
        let formatter = cache[key] ?? {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh-Hant")
            formatter.calendar = Calendar(identifier: .chinese)
            formatter.timeZone = timeZone
            cache[key] = formatter
            return formatter
        }()
        formatter.dateFormat = "MMM"
        let month = formatter.string(from: date)
        let day = lunarDayName(formatter.calendar.dateComponents(in: timeZone, from: date).day ?? 1)
        guard includeYear else { return month + day }

        formatter.dateFormat = "U"
        let year = formatter.string(from: date)
        let zodiac = year.last.flatMap { zodiacAnimals[$0] }.map { "（\($0)）" } ?? ""
        return "\(year)\(zodiac)年\(month)\(day)"
    }

    /// 初一…初十, 十一…十九, 二十, 廿一…廿九, 三十.
    private static func lunarDayName(_ day: Int) -> String {
        let digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        switch day {
        case 1...10: return "初" + digits[day]
        case 11...19: return "十" + digits[day - 10]
        case 20: return "二十"
        case 21...29: return "廿" + digits[day - 20]
        default: return "三十"
        }
    }

    /// Earthly branch (last character of the year name) → zodiac animal.
    private static let zodiacAnimals: [Character: String] = [
        "子": "鼠", "丑": "牛", "寅": "虎", "卯": "兔", "辰": "龍", "巳": "蛇",
        "午": "馬", "未": "羊", "申": "猴", "酉": "雞", "戌": "狗", "亥": "豬",
    ]

    /// "h" forces a 12-hour clock and "H" forces a 24-hour clock regardless of locale.
    static func timeTemplate(use24Hour: Bool, showSeconds: Bool) -> String {
        (use24Hour ? "HHmm" : "hmm") + (showSeconds ? "ss" : "") + (use24Hour ? "" : "a")
    }

    static func time(_ date: Date, in timeZone: TimeZone, preferences: Preferences) -> String {
        string(date, template: timeTemplate(use24Hour: preferences.use24Hour, showSeconds: preferences.showSeconds),
               in: timeZone)
    }

    /// "UTC+9", "UTC−3:30", "UTC".
    static func utcOffset(_ seconds: Int) -> String {
        seconds == 0 ? "UTC" : "UTC" + signedDuration(seconds)
    }

    /// Short zone abbreviation for the given instant, e.g. "PDT" in summer and "PST" in winter.
    static func abbreviation(of timeZone: TimeZone, at date: Date) -> String {
        let offset = utcOffset(timeZone.secondsFromGMT(for: date))
        guard let abbreviation = timeZone.abbreviation(for: date), !abbreviation.hasPrefix("GMT") else {
            return offset
        }
        return "\(abbreviation) · \(offset)"
    }

    /// Difference between a zone and local time, e.g. "+9h", "−3h", "+5:30h", or "Same time".
    static func difference(from local: TimeZone, to other: TimeZone, at date: Date) -> String {
        let seconds = other.secondsFromGMT(for: date) - local.secondsFromGMT(for: date)
        return seconds == 0 ? L("Same time") : L("%@h", signedDuration(seconds))
    }

    /// Whether the calendar day in `other` is before, the same as, or after the local day.
    static func dayRelation(from local: TimeZone, to other: TimeZone, at date: Date) -> String? {
        func dayNumber(in timeZone: TimeZone) -> Int {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let c = calendar.dateComponents([.year, .month, .day], from: date)
            return c.year! * 10_000 + c.month! * 100 + c.day!
        }
        let localDay = dayNumber(in: local), otherDay = dayNumber(in: other)
        if otherDay > localDay { return L("Tomorrow") }
        if otherDay < localDay { return L("Yesterday") }
        return nil
    }

    /// Describes an upcoming daylight-saving change within `window`, e.g. "Clocks go back 1h on Sun, Nov 1".
    static func upcomingTransition(in timeZone: TimeZone, after date: Date,
                                   within window: TimeInterval = 14 * 86_400) -> String? {
        guard let transition = timeZone.nextDaylightSavingTimeTransition(after: date),
              transition.timeIntervalSince(date) <= window else { return nil }
        let delta = timeZone.secondsFromGMT(for: transition + 60) - timeZone.secondsFromGMT(for: transition - 60)
        guard delta != 0 else { return nil }
        let amount = unsignedDuration(abs(delta))
        let day = string(transition, template: "EEEMMMd", in: timeZone)
        return delta > 0 ? L("Clocks go forward %1$@h on %2$@", amount, day)
                         : L("Clocks go back %1$@h on %2$@", amount, day)
    }

    private static func signedDuration(_ seconds: Int) -> String {
        (seconds < 0 ? "−" : "+") + unsignedDuration(abs(seconds))
    }

    private static func unsignedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return minutes == 0 ? "\(hours)" : String(format: "%d:%02d", hours, minutes)
    }
}
