//
//  Bookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient {
    func createBookmark(itemId: String, position: UInt64, note: String) async throws -> Bookmark {
        Bookmark(payload: try await response(for: ClientRequest<BookmarkPayload>(path: "api/me/item/\(itemId)/bookmark", method: .post, body: [
            "title": note,
            "time": position,
        ])))
    }
    
    func updateBookmark(itemId: String, position: UInt64, note: String) async throws -> Bookmark {
        Bookmark(payload: try await response(for: ClientRequest<BookmarkPayload>(path: "api/me/item/\(itemId)/bookmark", method: .patch, body: [
            "title": note,
            "time": position,
        ])))
    }
    
    func deleteBookmark(itemId: String, position: UInt64) async throws {
        let _ = try await response(for: ClientRequest<BookmarkPayload>(path: "api/me/item/\(itemId)/bookmark/\(Int(position))", method: .delete))
    }
}
