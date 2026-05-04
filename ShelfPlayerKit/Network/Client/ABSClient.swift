//
//  ABSClient.swift
//  ShelfPlayerKit
//

import Combine
import Foundation
@preconcurrency import Security
import OSLog

public let ABSClient = APIClientStore.shared

public final actor APIClientStore: Sendable {
    var storage: [ItemIdentifier.ConnectionID: Task<APIClient, Error>] = [:]
    private var observerSubscriptions = Set<AnyCancellable>()

    private init() {
        Task {
            await self.setupObservers()
        }
    }

    private func setupObservers() {
        OfflineMode.events.changed
            .sink { [weak self] _ in
                Self.scheduleInvalidation(for: self)
            }
            .store(in: &observerSubscriptions)
        PersistenceManager.shared.authorization.events.connectionsChanged
            .sink { [weak self] in
                Self.scheduleInvalidation(for: self)
            }
            .store(in: &observerSubscriptions)
    }

    private nonisolated static func scheduleInvalidation(for store: APIClientStore?) {
        guard let store else {
            return
        }

        Task { [store] in
            await store.invalidate()
        }
    }

    func client(for connectionID: ItemIdentifier.ConnectionID, ensureAvailabilityEstablished: Bool = true) async throws -> APIClient {
        if ensureAvailabilityEstablished {
            await OfflineMode.shared.ensureAvailabilityEstablished()
        }

        if storage[connectionID] == nil {
            storage[connectionID] = .init {
                try await APIClient(connectionID: connectionID, credentialProvider: AuthorizedAPIClientCredentialProvider(connectionID: connectionID))
            }
        }

        return try await storage[connectionID]!.value
    }

    func invalidate() {
        storage.removeAll(keepingCapacity: true)
    }

    public func flushClientCache() async {
        for client in storage.values {
            try? await client.value.flush()
        }
    }
}

public extension APIClientStore {
    subscript(_ connectionID: ItemIdentifier.ConnectionID) -> APIClient {
        get async throws {
            try await client(for: connectionID)
        }
    }

    static let shared = APIClientStore()
}
