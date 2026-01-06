import Foundation
import Defaults

@Observable @MainActor
public final class OfflineMode: Sendable {
    private(set) public var isEnabled: Bool
    private var unavailable = [ItemIdentifier.ConnectionID]()
    
    private init() {
        isEnabled = Defaults[.isOffline]
    }
    
    public static let shared = OfflineMode()
}

public extension OfflineMode {
    func setEnabled(_ isOffline: Bool) {
        self.isEnabled = isOffline
        unavailable.removeAll()
        
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
