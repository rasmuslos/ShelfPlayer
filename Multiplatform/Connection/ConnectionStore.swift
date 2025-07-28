//
//  Connections.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 07.01.25.
//

import Foundation
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class ConnectionStore {
    private(set) var didLoad: Bool
    
    private(set) var connections: [FriendlyConnection]
    private(set) var offlineConnections: [ItemIdentifier.ConnectionID]
    
    private(set) var libraries: [ItemIdentifier.ConnectionID: [Library]]
    
    init() {
        didLoad = false
        connections = []
        
        libraries = [:]
        offlineConnections = []
        
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
    }
    
    nonisolated func update() {
        Task {
            try await PersistenceManager.shared.authorization.waitForConnections()
            
            let connections = await PersistenceManager.shared.authorization.friendlyConnections.sorted {
                $0.name < $1.name
            }
            
            let libraries = await ShelfPlayerKit.libraries
            let grouped = Dictionary(grouping: libraries, by: { $0.connectionID })
            
            let offline = Array(connections).compactMap { grouped[$0.id] == nil ? $0.id : nil }
            
            await MainActor.withAnimation {
                didLoad = true
                
                self.connections = connections
                self.offlineConnections = offline
                
                self.libraries = grouped
            }
        }
    }
}
