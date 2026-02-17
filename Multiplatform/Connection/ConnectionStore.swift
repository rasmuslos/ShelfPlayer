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
    
    private init() {
        update()
        
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.update()
        }
    }
    
    var offlineConnections: [ItemIdentifier.ConnectionID] {
        connections.compactMap {
            OfflineMode.shared.isAvailable($0.id) ? nil : $0.id
        }
    }
    
    func update() {
        Task {
            try await PersistenceManager.shared.authorization.waitForConnections()
            
            let connections = await PersistenceManager.shared.authorization.friendlyConnections.sorted {
                $0.name < $1.name
            }
            
            didLoad = true
            
            withAnimation {
                self.connections = connections
            }
        }
    }
}

extension ConnectionStore {
    static let shared = ConnectionStore()
}
