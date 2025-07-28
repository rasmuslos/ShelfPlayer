//
//  AudiobookshelfClient+Libraries.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

public extension APIClient {
    func libraries() async throws -> [Library] {
        let response: LibrariesResponse = try await response(path: "api/libraries", method: .get)
        return response.libraries.map { Library(id: $0.id, connectionID: connectionID, name: $0.name, type: $0.mediaType, index: $0.displayOrder) }
    }
    
    func genres(from libraryID: ItemIdentifier.LibraryID) async throws -> [String] {
        let response: LibraryResponse = try await response(path: "api/libraries/\(libraryID)", method: .get, query: [
            .init(name: "include", value: "filterdata")
        ])
        return response.filterdata.genres
    }
}
