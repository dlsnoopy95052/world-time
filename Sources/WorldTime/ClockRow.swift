import SwiftUI

/// One clock line: city name, time, day/date, zone abbreviation, offset, and DST status.
struct ClockRow: View {
    let title: String
    let timeZone: TimeZone
    let isLocal: Bool
    var onRemove: (() -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    @EnvironmentObject private var clock: Clock
    @EnvironmentObject private var preferences: Preferences
    @State private var isHovering = false

    var body: some View {
        let now = clock.now
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    if isLocal { Badge(text: L("LOCAL"), color: .accentColor) }
                    if timeZone.isDaylightSavingTime(for: now) { Badge(text: L("DST"), color: .orange) }
                }
                Text(Formatters.string(now, template: "EEEMMMdyyyy", in: timeZone))
                    .font(.caption)
                if Localization.isChinese {
                    Text(L("Lunar calendar: %@", Formatters.lunarDate(now, in: timeZone)))
                        .font(.caption)
                }
                Text(Formatters.abbreviation(of: timeZone, at: now))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let transition = Formatters.upcomingTransition(in: timeZone, after: now) {
                    Label(transition, systemImage: "clock.arrow.2.circlepath")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.time(now, in: timeZone, preferences: preferences))
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .monospacedDigit()
                if !isLocal {
                    Text(relativeDescription(at: now))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(L("Remove %@", title))
                .opacity(isHovering ? 1 : 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isHovering && !isLocal ? Color.primary.opacity(0.06) : .clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .contextMenu {
            if let onMoveUp { Button(L("Move Up"), action: onMoveUp) }
            if let onMoveDown { Button(L("Move Down"), action: onMoveDown) }
            if let onRemove { Button(L("Remove"), role: .destructive, action: onRemove) }
        }
    }

    private func relativeDescription(at now: Date) -> String {
        let difference = Formatters.difference(from: .current, to: timeZone, at: now)
        guard let day = Formatters.dayRelation(from: .current, to: timeZone, at: now) else { return difference }
        return L("%1$@, %2$@", day, difference)
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
    }
}
