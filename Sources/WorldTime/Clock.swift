import AppKit
import Combine

/// Publishes the current instant, ticking exactly on second or minute boundaries.
///
/// Every time shown in the app is derived from this absolute instant plus an IANA time zone,
/// so daylight-saving transitions are applied automatically by the system time zone database.
/// The clock also refreshes immediately when the system time zone, clock, or calendar day
/// changes, and after the Mac wakes from sleep.
@MainActor
final class Clock: ObservableObject {
    @Published private(set) var now = Date()

    private var timer: Timer?
    private var interval: TimeInterval = 60
    private var cancellables = Set<AnyCancellable>()

    init(preferences: Preferences) {
        preferences.$showSeconds
            .sink { [weak self] showSeconds in
                MainActor.assumeIsolated {
                    self?.interval = showSeconds ? 1 : 60
                    self?.restart()
                }
            }
            .store(in: &cancellables)

        let systemChanges: [Notification.Name] = [
            .NSSystemTimeZoneDidChange,
            .NSSystemClockDidChange,
            .NSCalendarDayChanged,
            NSLocale.currentLocaleDidChangeNotification,
        ]
        let publishers = systemChanges.map { NotificationCenter.default.publisher(for: $0) }
            + [NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)]
        Publishers.MergeMany(publishers)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.systemDidChange() }
            }
            .store(in: &cancellables)
    }

    private func systemDidChange() {
        NSTimeZone.resetSystemTimeZone()
        Formatters.reset()
        restart()
    }

    private func restart() {
        timer?.invalidate()
        now = Date()

        // Align the first fire to the next whole second/minute so the display flips on time.
        let next = (now.timeIntervalSince1970 / interval).rounded(.down) * interval + interval
        let timer = Timer(fire: Date(timeIntervalSince1970: next), interval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = Date() }
        }
        timer.tolerance = interval == 1 ? 0.05 : 0.5
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
