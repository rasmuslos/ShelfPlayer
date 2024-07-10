//
//  AudiobookshelfClient+Narrators.swift
//  
//
//  Created by Rasmus Krämer on 21.06.24.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func audiobooks(narratorName: String, libraryId: String) async throws -> [Audiobook] {
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/items", method: "GET", query: [
            URLQueryItem(name: "filter", value: "narrators.\(narratorName.base64)"),
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "page", value: "0"),
        ]))
        
        return response.results.compactMap(Audiobook.init)
    }
}
