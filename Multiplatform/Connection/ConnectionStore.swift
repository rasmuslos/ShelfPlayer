//
//  Connections.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 07.01.25.
//

import Foundation
import SwiftUI
import Synchronization
import ShelfPlayback

@Observable @MainActor
final class ConnectionStore {
    private(set) var didLoad = false
    
    private(set) var connections = [FriendlyConnection]()
    private(set) var offlineConnections = [ItemIdentifier.ConnectionID]()
    
    private(set) var libraries = [ItemIdentifier.ConnectionID: [Library]]()
    
    // There is only a single instance of this class (enforced by the singleton)
    // and yet this mutex still does race... How?
    @ObservationIgnored private let reauthorizingConnectionIDs = Mutex([ItemIdentifier.ConnectionID]())
    
    private init() {
        update()
        
        RFNotification[.changeOfflineMode].subscribe { [weak self] isEnabled in
            guard !isEnabled else {
                return
            }
            
            self?.update()
        }
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.update()
        }
        RFNotification[.connectionUnauthorized].subscribe { [weak self] connectionID in
            self?.reauthorize(connectionID: connectionID)
        }
    }
    
    nonisolated func update() {
        Task {
            try await PersistenceManager.shared.authorization.waitForConnections()
            
            let connections = await PersistenceManager.shared.authorization.friendlyConnections.sorted {
                $0.name < $1.name
            }
            
            await MainActor.withAnimation {
                didLoad = true
                self.connections = connections
            }
            
            let libraries = await ShelfPlayerKit.libraries
            let grouped = Dictionary(grouping: libraries, by: { $0.connectionID })
            
            let offline = Array(connections).compactMap { grouped[$0.id] == nil ? $0.id : nil }
            
            await MainActor.withAnimation {
                self.offlineConnections = offline
                self.libraries = grouped
            }
            
            await RFNotification[.navigateConditionMet].send()
        }
    }
    func reauthorize(connectionID: ItemIdentifier.ConnectionID) {
        Task {
            try await Task.sleep(for: .milliseconds(300))
            
            let result = reauthorizingConnectionIDs.withLock {
                guard !$0.contains(connectionID) else {
                    return false
                }
                
                $0.append(connectionID)
                $0 = Array($0)
                return true
            }
            
            guard result else {
                return
            }
            
            await RFNotification[.presentSheet].send(payload: .reauthorizeConnection(connectionID))
        }
    }
}

extension ConnectionStore {
    static let shared = ConnectionStore()
}
