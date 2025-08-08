//
//  AudiobookshelfClient+Narrators.swift
//  
//
//  Created by Rasmus Krämer on 21.06.24.
//

import Foundation

public extension APIClient {
    func narrators(from libraryID: ItemIdentifier.LibraryID) async throws -> [Person] {
        let response: NarratorsResponse = try await response(path: "api/libraries/\(libraryID)/narrators", method: .get)
        return response.narrators.compactMap { Person(narrator: $0, libraryID: libraryID, connectionID: connectionID) }
    }
    
    func audiobooks(from libraryID: ItemIdentifier.LibraryID, narratorName: String, page: Int, limit: Int) async throws -> [Audiobook] {
        let response: ResultResponse = try await response(path: "api/libraries/\(libraryID)/items", method: .get, query: [
            URLQueryItem(name: "page", value: String(describing: page)),
            URLQueryItem(name: "limit", value: String(describing: limit)),
            URLQueryItem(name: "filter", value: "narrators.\(Data(narratorName.utf8).base64EncodedString())"),
        ])
        return response.results.compactMap { Audiobook(payload: $0, libraryID: libraryID, connectionID: connectionID) }
    }
}
