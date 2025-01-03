//
//  AudiobookshelfClient+Narrators.swift
//  
//
//  Created by Rasmus Krämer on 21.06.24.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient where I == ItemIdentifier.ConnectionID {
    func audiobooks(from libraryID: String, narratorName: String, page: Int, limit: Int) async throws -> [Audiobook] {
        try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryID)/items", method: .get, query: [
            URLQueryItem(name: "page", value: String(describing: page)),
            URLQueryItem(name: "limit", value: String(describing: limit)),
            URLQueryItem(name: "filter", value: "narrators.\(Data(narratorName.utf8).base64EncodedString())"),
        ])).results.compactMap { Audiobook(payload: $0, connectionID: connectionID) }
    }
}
