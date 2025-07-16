//
//  API+Collection.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.07.25.
//

import Foundation

public extension APIClient where I == ItemIdentifier.ConnectionID {
    
    func collection(with identifier: ItemIdentifier) async throws -> ItemCollection {
        let type: ItemCollection.CollectionType
        
        switch identifier.type {
            case .collection:
                type = .collection
            case .playlist:
                type = .playlist
            default:
                throw APIClientError.invalidHttpBody
        }
        
        return ItemCollection(payload: try await response(for: ClientRequest<ItemPayload>(path: "api/\(type.apiValue)/\(identifier.primaryID)", method: .get)), type: type, connectionID: connectionID)
    }
    func collections(in libraryID: String, type: ItemCollection.CollectionType, limit: Int?, page: Int?) async throws -> ([ItemCollection], Int) {
        var query: [URLQueryItem] = []
        
        if let page {
            query.append(.init(name: "page", value: String(page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(limit)))
        }
        
        let response = try await response(for: ClientRequest<ResultResponse>(path: "api/libraries/\(libraryID)/\(type.apiValue)", method: .get, query: query))
        return (response.results.map { ItemCollection(payload: $0, type: type, connectionID: connectionID) }, response.total)
    }
}
