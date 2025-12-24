//
//  ABSClient.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation
@preconcurrency import Security
import OSLog

public let ABSClient = APIClientStore.shared

public final actor APIClientStore: Sendable {
    var storage: [ItemIdentifier.ConnectionID: Task<APIClient, Error>] = [:]
    
    private init() {
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            Task {
                await self?.invalidate()
            }
        }
    }
    
    func client(for connectionID: ItemIdentifier.ConnectionID) async throws -> APIClient {
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
}

public extension APIClientStore {
    subscript(_ connectionID: ItemIdentifier.ConnectionID) -> APIClient {
        get async throws {
            try await client(for: connectionID)
        }
    }
    
    static let shared = APIClientStore()
}
