import Foundation

@Observable @MainActor
public final class OfflineMode: Sendable {
    nonisolated public static let availabilityTimeout: TimeInterval = 2.5
    
    private var availability = [ItemIdentifier.ConnectionID: Bool]()
    private var forcedEnabled = false
    private var availabilityEstablished = false
    private var establishAvailabilityTask: Task<Void, Never>?
    
    private init() {
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            Task {
                await self?.refreshAvailability()
            }
        }
    }
    
    public static let shared = OfflineMode()
    
    public var isEnabled: Bool {
        forcedEnabled || (!availability.isEmpty && availability.values.allSatisfy { !$0 })
    }
}

public extension OfflineMode {
    func markAsUnavailable(_ id: ItemIdentifier.ConnectionID) {
        var availability = availability
        availability[id] = false
        
        applyAvailability(availability)
    }
    func markAsAvailable(_ id: ItemIdentifier.ConnectionID) {
        var availability = availability
        availability[id] = true
        
        applyAvailability(availability)
    }
    
    func forceEnable() {
        setForcedEnabled(true)
    }
    
    func isAvailable(_ id: ItemIdentifier.ConnectionID) -> Bool {
        (availability[id] ?? true)
        && !forcedEnabled
    }
}

public extension OfflineMode {
    func refreshAvailability() async {
        setForcedEnabled(false)
        
        let availability = await PersistenceManager.shared.authorization.connectionAvailability()
        applyAvailability(availability)
    }
    
    func ensureAvailabilityEstablished() async {
        guard !availabilityEstablished else {
            return
        }
        
        let task: Task<Void, Never>
        
        if let establishAvailabilityTask {
            task = establishAvailabilityTask
        } else {
            let newTask = Task(priority: .userInitiated) {
                await refreshAvailability()
            }
            
            establishAvailabilityTask = newTask
            task = newTask
        }
        
        await task.value
        
        if establishAvailabilityTask == task {
            establishAvailabilityTask = nil
        }
    }
}

private extension OfflineMode {
    func setForcedEnabled(_ forcedEnabled: Bool) {
        let before = isEnabled
        self.forcedEnabled = forcedEnabled
        
        guard before != isEnabled else {
            return
        }
        
        RFNotification[.offlineModeChanged].dispatch(payload: isEnabled)
    }
    
    func applyAvailability(_ availability: [ItemIdentifier.ConnectionID: Bool]) {
        let before = isEnabled
        
        self.availability = availability
        availabilityEstablished = true
        
        guard before != isEnabled else {
            return
        }
        
        RFNotification[.offlineModeChanged].dispatch(payload: isEnabled)
    }
}
