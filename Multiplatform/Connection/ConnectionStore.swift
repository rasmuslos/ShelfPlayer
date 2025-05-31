//
//  Connections.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 07.01.25.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

@Observable @MainActor
final class ConnectionStore {
    var current: Connection?
    
    private(set) var didLoad: Bool
    
    private(set) var connections: [ItemIdentifier.ConnectionID: Connection]
    
    private(set) var libraries: [ItemIdentifier.ConnectionID: [Library]]
    private(set) var offlineConnections: [ItemIdentifier.ConnectionID]
    
    init() {
        didLoad = false
        connections = [:]
        
        libraries = [:]
        offlineConnections = []
        
        Task {
            try await PersistenceManager.shared.authorization.fetchConnections()
            connections = await PersistenceManager.shared.authorization.connections
            
            update()
            
            didLoad = true
        }
        
        RFNotification[.changeOfflineMode].subscribe { [weak self] isEnabled in
            guard !isEnabled else {
                return
            }
            
            self?.update()
        }
        RFNotification[.connectionsChanged].subscribe { [weak self] connections in
            withAnimation {
                self?.connections = connections
            }
            
            self?.update()
        }
    }
    
    nonisolated func update() {
        Task {
            let libraries = await ShelfPlayerKit.libraries
            let grouped = Dictionary(grouping: libraries, by: { $0.connectionID })
            
            let offline = await Array(connections.keys).filter { grouped[$0] == nil }
            
            await MainActor.withAnimation {
                self.offlineConnections = offline
                self.libraries = grouped
            }
            
            guard !libraries.isEmpty else {
                RFNotification[.changeOfflineMode].dispatch(payload: true)
                return
            }
        }
    }
    
    var flat: [Connection] {
        connections.values.sorted { $0.friendlyName < $1.friendlyName }
    }
}
