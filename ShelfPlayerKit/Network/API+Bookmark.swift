//
//  Bookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation

public extension APIClient {
    func createBookmark(primaryID: ItemIdentifier.PrimaryID, time: UInt64, note: String) async throws -> Date {
        let payload: BookmarkPayload = try await response(path: "api/me/item/\(primaryID)/bookmark", method: .post, body: [
            "title": note,
            "time": time,
        ])
        
        return Date(timeIntervalSince1970: payload.createdAt / 1000)
    }
    
    func updateBookmark(primaryID: ItemIdentifier.PrimaryID, time: UInt64, note: String) async throws {
        try await response(path: "api/me/item/\(primaryID)/bookmark", method: .patch, body: [
            "title": note,
            "time": time,
        ])
    }
    
    func deleteBookmark(primaryID: ItemIdentifier.PrimaryID, time: UInt64) async throws {
        try await response(path: "api/me/item/\(primaryID)/bookmark/\(time)", method: .delete)
    }
}
