//
//  Connections.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 07.01.25.
//

import Foundation
import SwiftUI
import RFNotifications
import ShelfPlayerKit

@Observable @MainActor
final class ConnectionStore {
    var current: PersistenceManager.AuthorizationSubsystem.Connection?
    
    private(set) var didLoad = false
    
    private(set) var connections: [ItemIdentifier.ConnectionID: PersistenceManager.AuthorizationSubsystem.Connection]
    private(set) var libraries: [ItemIdentifier.ConnectionID: [Library]]
    
    init() {
        connections = [:]
        libraries = [:]
        
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
            var libraries = [ItemIdentifier.ConnectionID: [Library]]()
            
            for connection in await connections {
                do {
                    libraries[connection.key] = try await ABSClient[connection.key].libraries()
                } catch {
                    continue
                }
            }
            
            guard !libraries.isEmpty else {
                RFNotification[.librariesEmpty].send()
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

extension RFNotification.Notification {
    static var librariesEmpty: RFNotification.Notification<RFNotificationEmptyPayload> {
        .init("io.rfk.shelfPlayer.librariesEmpty")
    }
}
