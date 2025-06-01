//
//  AudiobookshelfClient+Authors.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import RFNetwork


public extension APIClient where I == ItemIdentifier.ConnectionID {
    func author(with identifier: ItemIdentifier) async throws -> Person {
        Person(author: try await response(for: ClientRequest<ItemPayload>(path: "api/authors/\(identifier.pathComponent)", method: .get)), connectionID: connectionID)
    }
    
    func authors(from libraryID: String, sortOrder: AuthorSortOrder, ascending: Bool, limit: Int, page: Int) async throws -> ([Person], Int) {
        let response = try await response(for: ClientRequest<ResultResponse>(path: "api/libraries/\(libraryID)/authors", method: .get, query: [
            .init(name: "sort", value: sortOrder.queryValue),
            .init(name: "desc", value: ascending ? "0" : "1"),
            .init(name: "limit", value: String(limit)),
            .init(name: "page", value: String(page)),
        ]))
        
        return (response.results.map { Person(author: $0, connectionID: connectionID) }, response.total)
    }
    
    func authorID(from libraryID: String, name: String) async throws -> ItemIdentifier {
        let response = try await response(for: ClientRequest<SearchResponse>(path: "api/libraries/\(libraryID)/search", method: .get, query: [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "1"),
        ]))
        
        if let id = response.authors?.first?.id {
            return .init(primaryID: id,
                         groupingID: nil,
                         libraryID: libraryID,
                         connectionID: connectionID,
                         type: .author)
        }
        
        throw APIClientError.missing
    }
}
