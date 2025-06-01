//
//  Bookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import RFNetwork


public extension APIClient {
    func createBookmark(primaryID: ItemIdentifier.PrimaryID, time: UInt64, note: String) async throws -> Date {
        Date(timeIntervalSince1970: try await response(for: ClientRequest<BookmarkPayload>(path: "api/me/item/\(primaryID)/bookmark", method: .post, body: [
            "title": note,
            "time": time,
        ])).createdAt / 1000)
    }
    
    func updateBookmark(primaryID: ItemIdentifier.PrimaryID, time: UInt64, note: String) async throws {
        try await response(for: ClientRequest<Empty>(path: "api/me/item/\(primaryID)/bookmark", method: .patch, body: [
            "title": note,
            "time": time,
        ]))
    }
    
    func deleteBookmark(primaryID: ItemIdentifier.PrimaryID, time: UInt64) async throws {
        try await response(for: ClientRequest<Empty>(path: "api/me/item/\(primaryID)/bookmark/\(time)", method: .delete))
    }
}
