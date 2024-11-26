//
//  AudiobookshelfClient+Libraries.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func libraries() async throws -> [Library] {
        try await request(ClientRequest<LibrariesResponse>(path: "api/libraries", method: "GET")).libraries.map { Library(id: $0.id, name: $0.name, type: $0.mediaType, displayOrder: $0.displayOrder) }
    }
}
