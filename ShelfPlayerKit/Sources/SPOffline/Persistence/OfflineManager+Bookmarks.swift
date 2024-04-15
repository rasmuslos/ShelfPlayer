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
            let entity = Bookmark(itemId: bookmark.libraryItemId, episodeId: nil, note: bookmark.title, position: bookmark.time, status: .synced)
            PersistenceManager.shared.modelContainer.mainContext.insert(entity)
        }
    }
    
    @MainActor
    func syncRemoteBookmarks() async throws {
        // isn't it really inefficient to do this instead of two queries? maybe but SwiftData does not allow it any way else
        let bookmarks = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<Bookmark>())
        
        for entity in bookmarks.filter({ $0.status == .deleted }) {
            try? await AudiobookshelfClient.shared.deleteBookmark(itemId: entity.itemId, position: entity.position)
        }
        
        for entity in bookmarks.filter({ $0.status == .pending }) {
            let _ = try await AudiobookshelfClient.shared.createBookmark(itemId: entity.itemId, position: entity.position, note: entity.note)
        }
        
        // all entities will be deleted later
    }
}

public extension OfflineManager {
    @MainActor
    func createBookmark(itemId: String, position: Double, note: String) async {
        let entity: Bookmark
        
        if let bookmark = try? await AudiobookshelfClient.shared.createBookmark(itemId: itemId, position: position, note: note) {
            entity = Bookmark(itemId: bookmark.libraryItemId, episodeId: nil, note: bookmark.title, position: bookmark.time, status: .synced)
        } else {
            entity = Bookmark(itemId: itemId, episodeId: nil, note: note, position: position, status: .pending)
        }
        
        PersistenceManager.shared.modelContainer.mainContext.insert(entity)
        NotificationCenter.default.post(name: Self.bookmarksUpdatedNotification, object: itemId)
    }
    
    @MainActor
    func deleteBookmark(_ bookmark: Bookmark) async {
        do {
            try await AudiobookshelfClient.shared.deleteBookmark(itemId: bookmark.itemId, position: bookmark.position)
            PersistenceManager.shared.modelContainer.mainContext.delete(bookmark)
        } catch {
            bookmark.status = Bookmark.SyncStatus.deleted
        }
        
        NotificationCenter.default.post(name: Self.bookmarksUpdatedNotification, object: bookmark.itemId)
    }
    
    @MainActor
    func getBookmarks(itemId: String) throws -> [Bookmark] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<Bookmark>(predicate: #Predicate {
            $0.itemId == itemId
        }))
        // why is this not part of the predicate? because it does not compile
        .filter {
            $0.status != .deleted
        }
        .sorted {
            $0.position < $1.position
        }
    }
}
