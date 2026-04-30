//
//  WebSocketSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 10.01.26.
//

import Combine
import Foundation
import OSLog
import SocketIO

extension PersistenceManager {
    @MainActor
    public final class WebSocketSubsystem {
        public final class EventSource: @unchecked Sendable {
            public let librariesChanged = PassthroughSubject<Void, Never>()

            init() {}
        }

        private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "WebSocketSubsystem")

        private var isForegrounded = false
        private var updateTask: Task<Void, Never>?
        private var observerSubscriptions = Set<AnyCancellable>()
        public nonisolated let events = EventSource()

        private var connections = [ItemIdentifier.ConnectionID: SocketConnection]()

        nonisolated init() {
            Task { @MainActor [weak self] in
                self?.setupObservers()
            }
        }

        private func setupObservers() {
            OfflineMode.events.changed
                .sink { [weak self] _ in
                    Task { @MainActor in
                        self?.reevaluateConnections()
                    }
                }
                .store(in: &observerSubscriptions)

            AppEventSource.shared.scenePhaseDidChange
                .sink { [weak self] isActive in
                    Task { @MainActor in
                        self?.isForegrounded = isActive
                        self?.reevaluateConnections()
                    }
                }
                .store(in: &observerSubscriptions)
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
            logger.info("Created new socket for \(connection.id, privacy: .public). Initiating connect")
            bundle.socket.connect()
        }
    }
    func disconnect() {
        logger.info("Disconnecting \(self.connections.count, privacy: .public) socket(s)")

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
    private var observerSubscriptions = Set<AnyCancellable>()

    init(connection: FriendlyConnection) async {
        connectionID = connection.id

        logger.info("Creating new socket for \(self.connectionID, privacy: .public)")

        let headers: [HTTPHeader]?
        do {
            headers = try await ABSClient[connectionID].headers
        } catch {
            logger.warning("Failed to fetch headers for socket \(self.connectionID, privacy: .public); connecting without auth headers: \(error, privacy: .public)")
            headers = nil
        }

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

        socket.on("init") { [weak self] _, _ in
            self?.logger.info("Connection \(self?.connectionID ?? "<nil>") authorized")
        }

        // Library

        socket.on("library_updated") { [weak self] _, _ in
            self?.librariesChanged()
        }
        socket.on("library_added") { [weak self] _, _ in
            self?.librariesChanged()
        }
        socket.on("library_removed") { [weak self] _, _ in
            self?.librariesChanged()
        }

        // User

        socket.on("user_updated") { [weak self] data, _ in
            self?.userUpdated(data)
        }
        socket.on("user_item_progress_updated") { [weak self] data, _ in
            self?.userItemProgressUpdated(data)
        }

        // Items

        socket.on("item_added") { [weak self] data, _ in
            self?.itemUpdated(data, event: "item_added")
        }
        socket.on("item_updated") { [weak self] data, _ in
            self?.itemUpdated(data, event: "item_updated")
        }
        socket.on("item_removed") { [weak self] data, _ in
            self?.itemRemoved(data)
        }
        socket.on("items_added") { [weak self] data, _ in
            self?.itemsUpdated(data, event: "items_added")
        }
        socket.on("items_updated") { [weak self] data, _ in
            self?.itemsUpdated(data, event: "items_updated")
        }

        // Episodes

        socket.on("episode_added") { [weak self] data, _ in
            self?.episodeAdded(data)
        }

        // Series

        socket.on("series_updated") { [weak self] data, _ in
            self?.itemUpdated(data, event: "series_updated")
        }
        socket.on("series_removed") { [weak self] data, _ in
            self?.itemRemoved(data)
        }

        // Authors

        socket.on("author_added") { [weak self] data, _ in
            self?.itemUpdated(data, event: "author_added")
        }
        socket.on("author_updated") { [weak self] data, _ in
            self?.itemUpdated(data, event: "author_updated")
        }
        socket.on("author_removed") { [weak self] data, _ in
            self?.itemRemoved(data)
        }

        // Collections

        socket.on("collection_added") { [weak self] data, _ in
            self?.collectionChanged(data, event: "collection_added")
        }
        socket.on("collection_updated") { [weak self] data, _ in
            self?.collectionChanged(data, event: "collection_updated")
        }
        socket.on("collection_removed") { [weak self] data, _ in
            self?.collectionRemoved(data)
        }

        // Playlists

        socket.on("playlist_added") { [weak self] data, _ in
            self?.collectionChanged(data, event: "playlist_added")
        }
        socket.on("playlist_updated") { [weak self] data, _ in
            self?.collectionChanged(data, event: "playlist_updated")
        }
        socket.on("playlist_removed") { [weak self] data, _ in
            self?.collectionRemoved(data)
        }

        // Podcast episode downloads (server-side RSS pulls)

        socket.on("episode_download_finished") { [weak self] data, _ in
            self?.episodeDownloadFinished(data)
        }

        // Server-wide

        socket.on("backup_applied") { [weak self] _, _ in
            self?.backupApplied()
        }

        PersistenceManager.shared.authorization.events.accessTokenExpired
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.authorize()
                }
            }
            .store(in: &observerSubscriptions)
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

    func librariesChanged() {
        logger.info("Libraries changed. Sending update")
        PersistenceManager.shared.webSocket.events.librariesChanged.send()
    }

    func userUpdated(_ data: [Any]) {
        guard let payload = data.first else {
            logger.warning("Socket \(self.connectionID) received user_updated without payload")
            return
        }

        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload),
              let decoded = try? JSONDecoder().decode(UserUpdatedPayload.self, from: payloadData) else {
            logger.warning("Socket \(self.connectionID) failed to decode user_updated payload")
            return
        }

        receivedProgressUpdate(decoded.mediaProgress, event: "user_updated")
        librariesChanged()

        if let permissions = decoded.permissions {
            let connectionID = connectionID
            Task.detached {
                try? await PersistenceManager.shared.authorization.updatePermissions(permissions, for: connectionID)
            }
        }
    }
    func userItemProgressUpdated(_ data: [Any]) {
        guard let payload = data.first else {
            logger.warning("Socket \(self.connectionID) received user_item_progress_updated without payload")
            return
        }

        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload),
              let decoded = try? JSONDecoder().decode(UserItemProgressUpdatedPayload.self, from: payloadData) else {
            logger.warning("Socket \(self.connectionID) failed to decode user_item_progress_updated payload")
            return
        }

        receivedProgressUpdate([decoded.data], event: "user_item_progress_updated")
    }
    func receivedProgressUpdate(_ payload: [ProgressPayload], event: String) {
        Task.detached {
            for payload in payload {
                await PersistenceManager.shared.progress.receivedProgressUpdate(payload, connectionID: self.connectionID)
            }

            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                PlaybackLifecycleEventSource.shared.invalidateTransientPanels.send()
            }
        }
    }

    func itemUpdated(_ data: [Any], event: String) {
        guard let identifier = decodeIdentifier(from: data, event: event) else {
            return
        }

        emitItemUpdated(primaryID: identifier.id, groupingID: nil)
    }
    func itemRemoved(_ data: [Any]) {
        guard let identifier = decodeIdentifier(from: data, event: "item_removed") else {
            return
        }

        emitItemDeleted(primaryID: identifier.id, groupingID: nil)
    }
    func itemsUpdated(_ data: [Any], event: String) {
        guard let payload = data.first as? [Any] else {
            logger.warning("Socket \(self.connectionID) received \(event) without array payload")
            return
        }

        for entry in payload {
            guard let identifier = decodeIdentifier(from: [entry], event: event) else {
                continue
            }

            emitItemUpdated(primaryID: identifier.id, groupingID: nil)
        }
    }
    func episodeAdded(_ data: [Any]) {
        guard let payload = data.first as? [String: Any] else {
            logger.warning("Socket \(self.connectionID) received episode_added without payload")
            return
        }

        guard let podcastID = payload["libraryItemId"] as? String else {
            logger.warning("Socket \(self.connectionID) received episode_added without libraryItemId")
            return
        }

        let episodeID = payload["id"] as? String

        emitItemUpdated(primaryID: podcastID, groupingID: nil)
        if let episodeID {
            emitItemUpdated(primaryID: episodeID, groupingID: podcastID)
        }
    }

    func collectionChanged(_ data: [Any], event: String) {
        guard let identifier = decodeIdentifier(from: data, event: event) else {
            return
        }

        emitItemUpdated(primaryID: identifier.id, groupingID: nil)
        CollectionEventSource.shared.changed.send(makeIdentifier(primaryID: identifier.id, libraryID: identifier.libraryID, type: .collection))
    }
    func collectionRemoved(_ data: [Any]) {
        guard let identifier = decodeIdentifier(from: data, event: "collection_removed") else {
            return
        }

        emitItemDeleted(primaryID: identifier.id, groupingID: nil)

        let itemID = makeIdentifier(primaryID: identifier.id, libraryID: identifier.libraryID, type: .collection)
        CollectionEventSource.shared.changed.send(itemID)
        CollectionEventSource.shared.deleted.send(itemID)
    }

    func episodeDownloadFinished(_ data: [Any]) {
        guard let payload = data.first as? [String: Any],
              let libraryItemID = payload["libraryItemId"] as? String else {
            logger.warning("Socket \(self.connectionID) received episode_download_finished without libraryItemId")
            return
        }

        emitItemUpdated(primaryID: libraryItemID, groupingID: nil)
    }

    func backupApplied() {
        logger.info("Socket \(self.connectionID) received backup_applied; flushing caches")

        Task.detached {
            try? await PersistenceManager.shared.invalidateCache()
            await ResolveCache.shared.flush()

            await MainActor.run {
                PersistenceManager.shared.webSocket.events.librariesChanged.send()
            }
        }
    }
}

private extension SocketConnection {
    func decodeIdentifier(from data: [Any], event: String) -> (id: String, libraryID: String?)? {
        guard let payload = data.first as? [String: Any] else {
            logger.warning("Socket \(self.connectionID) received \(event) without payload")
            return nil
        }

        guard let id = payload["id"] as? String else {
            logger.warning("Socket \(self.connectionID) received \(event) without id")
            return nil
        }

        return (id, payload["libraryId"] as? String)
    }

    func makeIdentifier(primaryID: String, libraryID: String?, type: ItemIdentifier.ItemType) -> ItemIdentifier {
        .init(primaryID: primaryID, groupingID: nil, libraryID: libraryID ?? "", connectionID: connectionID, type: type)
    }

    func emitItemUpdated(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?) {
        let connectionID = connectionID

        Task.detached {
            await ResolveCache.shared.invalidate(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)

            await MainActor.run {
                ItemEventSource.shared.updated.send((connectionID: connectionID, primaryID: primaryID, groupingID: groupingID))
            }
        }
    }
    func emitItemDeleted(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?) {
        let connectionID = connectionID

        Task.detached {
            await ResolveCache.shared.invalidate(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)

            await MainActor.run {
                ItemEventSource.shared.deleted.send((connectionID: connectionID, primaryID: primaryID, groupingID: groupingID))
            }
        }
    }
}

private struct UserUpdatedPayload: Decodable {
    let mediaProgress: [ProgressPayload]
    let permissions: UserPermissionsPayload?
}
private struct UserItemProgressUpdatedPayload: Decodable {
    let data: ProgressPayload
}
