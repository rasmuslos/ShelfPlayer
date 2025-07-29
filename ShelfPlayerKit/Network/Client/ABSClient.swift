//
//  ABSClient.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation
@preconcurrency import Security
import OSLog

public let ABSClient = APIClientStore()

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
}

final actor AuthorizedAPIClientCredentialProvider: APICredentialProvider {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "AuthorizedAPIClientCredentialProvider")
    
    let connectionID: ItemIdentifier.ConnectionID
    
    var token: String
    var configuration: (URL, [HTTPHeader])
    
    var knownExpiredTokens: Set<String> = []
    
    var accessToken: String? {
        token
    }
    
    init(connectionID: ItemIdentifier.ConnectionID) async throws {
        self.connectionID = connectionID
        
        token = try await PersistenceManager.shared.authorization.accessToken(for: connectionID)
        configuration = try await PersistenceManager.shared.authorization.configuration(for: connectionID)
    }
    
    func refreshAccessToken(current: String?) async throws -> String? {
        guard !knownExpiredTokens.contains(token) else {
            return nil
        }
        
        if token == current {
            knownExpiredTokens.insert(token)
            
            logger.info("Access token for \(self.connectionID) expired. Refreshing...")
            
            do {
                token = try await PersistenceManager.shared.authorization.refreshAccessToken(for: connectionID)
            } catch {
                await PersistenceManager.shared.remove(connectionID: connectionID)
            }
        }
        
        return token
    }
}
