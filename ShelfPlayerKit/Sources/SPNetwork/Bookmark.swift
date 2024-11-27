//
//  Bookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func createBookmark(itemId: String, position: UInt64, note: String) async throws -> Bookmark {
        Bookmark(payload: try await request(ClientRequest<BookmarkPayload>(path: "api/me/item/\(itemId)/bookmark", method: "POST", body: [
            "title": note,
            "time": position,
        ])))
    }
    
    func updateBookmark(itemId: String, position: UInt64, note: String) async throws -> Bookmark {
        Bookmark(payload: try await request(ClientRequest<BookmarkPayload>(path: "api/me/item/\(itemId)/bookmark", method: "PATCH", body: [
            "title": note,
            "time": position,
        ])))
    }
    
    func deleteBookmark(itemId: String, position: UInt64) async throws {
        let _ = try await request(ClientRequest<BookmarkPayload>(path: "api/me/item/\(itemId)/bookmark/\(Int(position))", method: "DELETE"))
    }
}
