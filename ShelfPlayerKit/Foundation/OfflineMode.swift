import Foundation
import Defaults

@Observable @MainActor
public final class OfflineMode: Sendable {
    private(set) public var isEnabled: Bool
    
    private var unavailable = [ItemIdentifier.ConnectionID]()
    
    init() {
        isEnabled = Defaults[.isOffline]
    }
    
    public static let shared = OfflineMode()
    public static func setEnabled(_ isOffline: Bool) {
        Task {
            OfflineMode.shared.setEnabled(isOffline)
        }
    }
}

public extension OfflineMode {
    func setEnabled(_ isOffline: Bool) {
        self.isEnabled = isOffline
        Defaults[.isOffline] = isOffline
        
        RFNotification[.offlineModeChanged].send(payload: isOffline)
    }
    func markAsUnavailable(_ id: ItemIdentifier.ConnectionID) {
        unavailable.append(id)
    }
    
    func isAvailable(_ id: ItemIdentifier.ConnectionID) -> Bool {
        !unavailable.contains(id)
    }
}
