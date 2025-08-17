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

public final actor APIClientStore {
    var storage = [ItemIdentifier.ConnectionID: APIClient]()
    var busy = Set<ItemIdentifier.ConnectionID>()
    
    fileprivate init() {
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            Task {
                await self?.invalidate()
            }
        }
    }
    func invalidate() {
        storage.removeAll(keepingCapacity: true)
    }
    
    public subscript(_ connectionID: ItemIdentifier.ConnectionID) -> APIClient {
        get async throws {
            while busy.contains(connectionID) {
                try await Task.sleep(for: .seconds(0.1))
            }
            
            if let client = storage[connectionID] {
                return client
            }
            
            busy.insert(connectionID)
            
            do {
                let provider = try await AuthorizedAPIClientCredentialProvider(connectionID: connectionID)
                let client = try await APIClient(connectionID: connectionID, credentialProvider: provider)
                
                storage[connectionID] = client
                busy.remove(connectionID)
                
                return client
            } catch {
                busy.remove(connectionID)
                throw error
            }
        }
    }
    
    public static let shared = APIClientStore()
}
