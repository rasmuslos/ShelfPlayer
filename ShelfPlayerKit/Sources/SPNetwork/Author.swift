//
//  AudiobookshelfClient+Authors.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient where I == ItemIdentifier.ServerID {
    func author(with identifier: ItemIdentifier) async throws -> Author {
        Author(payload: try await request(ClientRequest<ItemPayload>(path: "api/authors/\(identifier.pathComponent)", method: .get)), serverID: serverID)
    }
    
    func author(with identifier: ItemIdentifier) async throws -> (Author, [Audiobook], [Series]) {
        let response = try await request(ClientRequest<ItemPayload>(path: "api/authors/\(identifier.pathComponent)", method: .get, query: [
            URLQueryItem(name: "library", value: identifier.libraryID),
            URLQueryItem(name: "include", value: "items,series"),
        ]))
        
        let author = Author(payload: response, serverID: serverID)
        let audiobooks = (response.libraryItems ?? []).compactMap { Audiobook(payload: $0, serverID: serverID) }
        let series = (response.series ?? []).map{ Series(payload: $0, serverID: serverID) }
        
        return (author, audiobooks, series)
    }
    
    func authors(from libraryID: String) async throws -> [Author] {
        try await request(ClientRequest<AuthorsResponse>(path: "api/libraries/\(libraryID)/authors", method: .get)).authors.map { Author(payload: $0, serverID: serverID) }
    }
    
    func authorID(from libraryID: String, name: String) async throws -> String {
        let response = try await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryID)/search", method: .get, query: [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "1"),
        ]))
        
        if let id = response.authors?.first?.id {
            return id
        }
        
        throw APIClientError.missing
    }
}
