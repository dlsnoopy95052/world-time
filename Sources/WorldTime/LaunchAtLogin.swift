import Foundation
import ServiceManagement

/// Registers the app as a login item using the macOS 13+ `SMAppService` API.
@MainActor
final class LaunchAtLogin: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var problem: Problem?

    enum Problem: Equatable {
        case requiresApproval
        case failed(String)

        @MainActor var message: String {
            switch self {
            case .requiresApproval: L("Allow World Time in System Settings › General › Login Items.")
            case .failed(let error): L("Couldn't update login item: %@", error)
            }
        }
    }

    init() {
        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled || status == .requiresApproval
        problem = status == .requiresApproval ? .requiresApproval : nil
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refresh()
        } catch {
            refresh()
            problem = .failed(error.localizedDescription)
        }
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
