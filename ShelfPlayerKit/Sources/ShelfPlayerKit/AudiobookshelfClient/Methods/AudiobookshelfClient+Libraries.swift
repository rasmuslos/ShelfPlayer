//
//  AudiobookshelfClient+Libraries.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

public extension AudiobookshelfClient {
    func getLibraries() async throws -> [Library] {
        let response = try await request(ClientRequest<LibrariesResponse>(path: "api/libraries", method: "GET"))
        return response.libraries.map { Library(id: $0.id, name: $0.name, type: $0.mediaType, displayOrder: $0.displayOrder) }
    }
}
