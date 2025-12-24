//
//  AudiobookshelfClient+Libraries.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

public extension APIClient {
    func libraries() async throws -> [Library] {
        try await response(APIRequest<LibrariesResponse>(path: "api/libraries", method: .get, ttl: 12, bypassesOffline: true)).libraries.map { Library(id: $0.id, connectionID: connectionID, name: $0.name, type: $0.mediaType, index: $0.displayOrder) }
    }
    
    func genres(from libraryID: ItemIdentifier.LibraryID) async throws -> [String] {
        try await response(APIRequest<LibraryResponse>(path: "api/libraries/\(libraryID)", method: .get, query: [.init(name: "include", value: "filterdata")])).filterdata.genres
    }
}

