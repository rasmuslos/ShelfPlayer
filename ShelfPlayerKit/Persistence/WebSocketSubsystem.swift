//
//  WebSocketSubsystem.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.01.26.
//

import Foundation
import OSLog
import SocketIO

extension PersistenceManager {
    @MainActor
    public final class WebSocketSubsystem {
        private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "WebSocketSubsystem")
        
        private var isForegrounded = false
        private var updateTask: Task<Void, Never>?
        
        private var connections = [ItemIdentifier.ConnectionID: SocketConnection]()
        
        nonisolated init() {
            RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
                Task { @MainActor in
                    self?.reevaluateConnections()
                }
            }
            RFNotification[.scenePhaseDidChange].subscribe { [weak self] isActive in
                Task { @MainActor in
                    self?.isForegrounded = isActive
                    self?.reevaluateConnections()
                }
            }
        }
    }
}

#if DEBUG
public extension PersistenceManager.WebSocketSubsystem {
    var connected: Int {
        connections.count
    }
    func reconnect() {
        disconnect()
        reevaluateConnections()
    }
}
#endif

private extension PersistenceManager.WebSocketSubsystem {
    func reevaluateConnections() {
        updateTask?.cancel()
        updateTask = .init {
            try? await Task.sleep(for: .seconds(1))
            
            guard !Task.isCancelled else {
                return
            }
            
            await performUpdate()
        }
    }
    
    // async operations should be avoided to avoid socket.io race conditions
    func performUpdate() async {
        await OfflineMode.shared.ensureAvailabilityEstablished()
        
        let isOffline = OfflineMode.shared.isEnabled
        let connectionsList = await PersistenceManager.shared.authorization.friendlyConnections
        
        guard !isOffline && isForegrounded else {
            disconnect()
            return
        }
        
        for connection in connectionsList {
            guard connections[connection.id] == nil else {
                logger.info("Socket \(connection.name) already exists")
                continue
            }
            
            let bundle = await SocketConnection(connection: connection)
            
            connections[connection.id] = bundle
            bundle.socket.connect()
        }
    }
    func disconnect() {
        logger.info("Disconnecting all sockets")
        
        for connection in connections.values {
            connection.manager.disconnect()
        }
        
        connections.removeAll(keepingCapacity: true)
    }
}

@MainActor
private final class SocketConnection {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "WebSocketConnection")

    let connectionID: ItemIdentifier.ConnectionID
    
    let manager: SocketManager
    let socket: SocketIOClient
    
    init(connection: FriendlyConnection) async {
        connectionID = connection.id
        
        logger.info("Creating new socket for \(self.connectionID)")
        
        let headers = try? await ABSClient[connectionID].headers
        
        manager = SocketManager(socketURL: connection.host, config: [
            .forceWebsockets(true),
            .reconnects(true),
            .reconnectAttempts(-1),
            .extraHeaders(Dictionary(uniqueKeysWithValues: headers?.map { ($0.key, $0.value) } ?? []))
        ])
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?.logger.info("Socket \(self?.connectionID ?? "<nil>") connected. Authorizing...")
            
            Task {
                await self?.authorize()
            }
        }
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.logger.info("Socket \(self?.connectionID ?? "<nil>") disconnected")
        }
        socket.on(clientEvent: .error) { [weak self] data, _ in
            self?.logger.error("Socket \(self?.connectionID ?? "<nil>") error: \(data)")
        }
        socket.on(clientEvent: .reconnect) { [weak self] _, _ in
            self?.logger.info("Socket \(self?.connectionID ?? "<nil>") reconnected")
        }
        socket.on(clientEvent: .reconnectAttempt) { [weak self] _, _ in
            self?.logger.info("Socket \(self?.connectionID ?? "<nil>") reconnect attempt")
        }
        socket.on(clientEvent: .statusChange) { [weak self] data, _ in
            self?.logger.info("Socket \(self?.connectionID ?? "<nil>") status change: \(data)")
        }
        
        // https://github.com/advplyr/audiobookshelf/blob/122fc34a75a6730f99736c3ae01186871b3d90ef/client/layouts/default.vue#L399
        // https://github.com/advplyr/audiobookshelf/blob/master/server/SocketAuthority.js#L179
        // https://github.com/advplyr/audiobookshelf-app/blob/master/plugins/server.js#L85
        
        socket.on("init") { [weak self] _, _ in
            self?.logger.info("Connection \(self?.connectionID ?? "<nil>") authorized")
        }
        
        RFNotification[.accessTokenExpired].subscribe { [weak self] _ in
            Task {
                await self?.authorize()
            }
        }
    }
    
    func authorize() async {
        let accessToken: String
        
        do {
            accessToken = try await PersistenceManager.shared.authorization.accessToken(for: self.connectionID)
        } catch {
            logger.error("Failed to get access token for \(self.connectionID): \(error)")
            return
        }
        
        guard socket.status == .connected else {
            logger.warning("Tried to authorize socket but it is not connected")
            return
        }
        
        socket.emit("auth", accessToken)
    }
}
