import Foundation
import Defaults

@Observable @MainActor
public final class OfflineMode: Sendable {
    private(set) public var isEnabled: Bool
    
    init() {
        isEnabled = Defaults[.isOffline]
    }
    public func setEnabled(_ isOffline: Bool) {
        self.isEnabled = isOffline
        Defaults[.isOffline] = isOffline
        
        RFNotification[.offlineModeChanged].send(payload: isOffline)
    }
    
    public static let shared = OfflineMode()
    public static func setEnabled(_ isOffline: Bool) {
        Task {
            OfflineMode.shared.setEnabled(isOffline)
        }
    }
}
