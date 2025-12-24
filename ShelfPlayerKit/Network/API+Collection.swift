//
//  API+Collection.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.07.25.
//

import Foundation

public extension APIClient {
    func createCollection(name: String, type: ItemCollection.CollectionType, libraryID: ItemIdentifier.LibraryID, itemIDs: [ItemIdentifier]) async throws -> ItemIdentifier {
        let payload: ItemPayload
        
        switch type {
            case .collection:
                payload = try await response(APIRequest<ItemPayload>(path: "api/collections", method: .post, body: CreateCollectionBooksPayload(name: name, libraryId: libraryID, books: itemIDs.map(\.primaryID))))
            case .playlist:
                payload = try await response(APIRequest<ItemPayload>(path: "api/playlists", method: .post, body: CreateCollectionItemsPayload(name: name, libraryId: libraryID, items: itemIDs.map {
                    .init(libraryItemId: $0.apiItemID, episodeId: $0.apiEpisodeID)
                })))
        }
        
        return .init(primaryID: payload.id, groupingID: nil, libraryID: libraryID, connectionID: connectionID, type: type.itemType)
    }
    
    func updateCollection(_ itemID: ItemIdentifier, name: String, description: String?) async throws {
        let type = itemIdentifierToCollectionType(itemID)
        let _ = try await response(APIRequest<EmptyResponse>(path: "api/\(type.apiValue)/\(itemID.primaryID)", method: .patch, body: UpdateCollectionPayload(name: name, description: description)))
    }
    func updateCollection(_ itemID: ItemIdentifier, itemIDs: [ItemIdentifier]) async throws {
        let type = itemIdentifierToCollectionType(itemID)
        
        switch type {
            case .collection:
                let _ = try await response(APIRequest<EmptyResponse>(path: "api/collections/\(itemID.primaryID)", method: .patch, body: UpdateCollectionBooksPayload(books: itemIDs.map(\.primaryID))))
            case .playlist:
                let _ = try await response(APIRequest<EmptyResponse>(path: "api/playlists/\(itemID.primaryID)", method: .patch, body: UpdateCollectionItemsPayload(items: itemIDs.map {
                    CollectionItemPayload(libraryItemId: $0.apiItemID, episodeId: $0.apiEpisodeID)
                })))
        }
    }
    
    func bulkUpdateCollectionItems(_ collectionID: ItemIdentifier, operation: CollectionBulkOperation, itemIDs: [ItemIdentifier]) async throws {
        let type = itemIdentifierToCollectionType(collectionID)
        
        switch type {
            case .collection:
                let _ = try await response(APIRequest<EmptyResponse>(path: "api/collections/\(collectionID.primaryID)/batch/\(operation.rawValue)", method: .post, body: UpdateCollectionBooksPayload(books: itemIDs.map(\.primaryID))))
            case .playlist:
                let _ = try await response(APIRequest<EmptyResponse>(path: "api/playlists/\(collectionID.primaryID)/batch/\(operation.rawValue)", method: .post, body: UpdateCollectionItemsPayload(items: itemIDs.map {
                    CollectionItemPayload(libraryItemId: $0.apiItemID, episodeId: $0.apiEpisodeID)
                })))
        }
    }
    enum CollectionBulkOperation: String {
        case add
        case remove
    }
    
    func deleteCollection(_ collectionID: ItemIdentifier) async throws {
        let type = itemIdentifierToCollectionType(collectionID)
        let _ = try await response(APIRequest<EmptyResponse>(path: "api/\(type.apiValue)/\(collectionID.primaryID)", method: .delete))
    }
    
    func collection(with identifier: ItemIdentifier) async throws -> ItemCollection {
        let type = itemIdentifierToCollectionType(identifier)
        return try await ItemCollection(payload: response(APIRequest(path: "api/\(type.apiValue)/\(identifier.primaryID)", method: .get, ttl: 12)), type: type, connectionID: connectionID)
    }
    func collections(in libraryID: String, type: ItemCollection.CollectionType, limit: Int?, page: Int?) async throws -> ([ItemCollection], Int) {
        var query: [URLQueryItem] = []
        
        if let page {
            query.append(.init(name: "page", value: String(page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(limit)))
        }
        
        let response = try await response(APIRequest<ResultResponse>(path: "api/libraries/\(libraryID)/\(type.apiValue)", method: .get, query: query, ttl: 12))
        return (response.results.map { ItemCollection(payload: $0, type: type, connectionID: connectionID) }, response.total)
    }
    
    func createPlaylistCopy(collectionID: ItemIdentifier) async throws -> ItemIdentifier {
        let response: ItemPayload = try await response(APIRequest<ItemPayload>(path: "api/playlists/collection/\(collectionID.primaryID)", method: .post))
        return .init(primaryID: response.id, groupingID: nil, libraryID: collectionID.libraryID, connectionID: connectionID, type: .playlist)
    }
    
    private func itemIdentifierToCollectionType(_ identifier: ItemIdentifier) -> ItemCollection.CollectionType {
        switch identifier.type {
            case .collection:
                return .collection
            case .playlist:
                return .playlist
            default:
                fatalError("Unsupported item type \(identifier.type)")
        }
    }
}
