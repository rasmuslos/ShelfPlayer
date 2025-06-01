//
//  AudiobookshelfClient+Libraries.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import RFNetwork


public extension APIClient where I == ItemIdentifier.ConnectionID {
    func libraries() async throws -> [Library] {
        try await response(for: ClientRequest<LibrariesResponse>(path: "api/libraries", method: .get)).libraries.map { Library(id: $0.id, connectionID: connectionID, name: $0.name, type: $0.mediaType, index: $0.displayOrder) }
    }
    
    func genres(from libraryID: ItemIdentifier.LibraryID) async throws -> [String] {
        try await response(for: ClientRequest<LibraryResponse>(path: "api/libraries/\(libraryID)", method: .get, query: [
            .init(name: "include", value: "filterdata")
        ])).filterdata.genres
    }
}
