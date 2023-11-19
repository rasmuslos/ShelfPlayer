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
        return response.libraries.map { Library(id: $0.id, name: $0.name, type: $0.convertMediaType(), displayOrder: $0.displayOrder) }
    }
    
    struct LibrariesResponse: Codable {
        let libraries: [Library]
        
        struct Library: Codable {
            let id: String
            let name: String
            let mediaType: String
            let displayOrder: Int
        }
    }
}

// MARK: Convert

extension AudiobookshelfClient.LibrariesResponse.Library {
    func convertMediaType() -> Library.MediaType! {
        if mediaType == "book" {
            return .audiobooks
        } else if mediaType == "podcast" {
            return .podcasts
        }
        
        return nil
    }
}
