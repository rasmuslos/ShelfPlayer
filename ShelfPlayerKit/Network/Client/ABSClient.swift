//
//  ABSClient.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

public let ABSClient = APIClientStore()

public final actor APIClientStore {
    fileprivate init() {
        
    }
    
    public subscript(_ connectionID: ItemIdentifier.ConnectionID) -> APIClient {
        get async throws {
            throw APIClientError.notFound
        }
    }
}
