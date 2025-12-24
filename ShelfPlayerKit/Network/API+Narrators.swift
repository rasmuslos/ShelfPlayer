//
//  AudiobookshelfClient+Narrators.swift
//  
//
//  Created by Rasmus Krämer on 21.06.24.
//

import Foundation

public extension APIClient {
    func narrators(from libraryID: ItemIdentifier.LibraryID) async throws -> [Person] {
        try await response(APIRequest<NarratorsResponse>(path: "api/libraries/\(libraryID)/narrators", method: .get, ttl: 12)).narrators.compactMap { Person(narrator: $0, libraryID: libraryID, connectionID: connectionID) }
    }
    
    func audiobooks(from libraryID: ItemIdentifier.LibraryID, narratorName: String, page: Int, limit: Int) async throws -> [Audiobook] {
        try await response(APIRequest<ResultResponse>(path: "api/libraries/\(libraryID)/items", method: .get, query: [
            URLQueryItem(name: "page", value: String(describing: page)),
            URLQueryItem(name: "limit", value: String(describing: limit)),
            URLQueryItem(name: "filter", value: "narrators.\(Data(narratorName.utf8).base64EncodedString())"),
        ], ttl: 12)).results.compactMap { Audiobook(payload: $0, libraryID: libraryID, connectionID: connectionID) }
    }
}

