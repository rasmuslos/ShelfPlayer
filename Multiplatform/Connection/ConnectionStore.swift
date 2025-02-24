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
    var current: PersistenceManager.AuthorizationSubsystem.Connection?
    
    private(set) var didLoad = false
    
    private(set) var connections: [ItemIdentifier.ConnectionID: PersistenceManager.AuthorizationSubsystem.Connection]
    
    private(set) var libraries: [ItemIdentifier.ConnectionID: [Library]]
    private(set) var offlineConnections: [ItemIdentifier.ConnectionID]
    
    init() {
        connections = [:]
        
        libraries = [:]
        offlineConnections = []
        
        Task {
            try await PersistenceManager.shared.authorization.fetchConnections()
            connections = await PersistenceManager.shared.authorization.connections
            
            update()
            
            didLoad = true
        }
        
        RFNotification[.connectionsChanged].subscribe { [weak self] connections in
            withAnimation {
                self?.connections = connections
                self?.update()
            }
        }
    }
    
    nonisolated func update() {
        Task {
            var offline = [ItemIdentifier.ConnectionID]()
            var libraries = [ItemIdentifier.ConnectionID: [Library]]()
            
            for connection in await connections {
                do {
                    libraries[connection.key] = try await ABSClient[connection.key].libraries()
                } catch {
                    offline.append(connection.key)
                    continue
                }
            }
            
            await MainActor.withAnimation {
                self.offlineConnections = offline
            }
            
            guard !libraries.isEmpty else {
                RFNotification[.changeOfflineMode].send(true)
                return
            }
            
            await MainActor.withAnimation {
                self.libraries = libraries
            }
        }
    }
    
    var flat: [PersistenceManager.AuthorizationSubsystem.Connection] {
        Array(connections.values)
    }
}
