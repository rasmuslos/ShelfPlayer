//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 14.04.24.
//

import Foundation
import SwiftData
import SPBase

extension OfflineManager {
    @MainActor
    func deleteBookmarks() throws {
        try PersistenceManager.shared.modelContainer.mainContext.delete(model: Bookmark.self)
    }
    
    @MainActor
    func syncLocalBookmarks(bookmarks: [AudiobookshelfClient.Bookmark]) throws {
        for bookmark in bookmarks {
            let entity = Bookmark(itemId: bookmark.libraryItemId, episodeId: nil, note: bookmark.title, position: bookmark.time)
            PersistenceManager.shared.modelContainer.mainContext.insert(entity)
        }
    }
}

public extension OfflineManager {
    @MainActor
    func createBookmark(itemId: String, position: Double, note: String) async throws {
        let bookmark = try await AudiobookshelfClient.shared.createBookmark(itemId: itemId, position: position, note: note)
        let entity = Bookmark(itemId: bookmark.libraryItemId, episodeId: nil, note: bookmark.title, position: bookmark.time)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(entity)
        NotificationCenter.default.post(name: Self.bookmarksUpdatedNotification, object: bookmark.libraryItemId)
    }
    
    @MainActor
    func getBookmarks(itemId: String) throws -> [Bookmark] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<Bookmark>(predicate: #Predicate {
            $0.itemId == itemId
        })).sorted {
            $0.position < $1.position
        }
    }
}
