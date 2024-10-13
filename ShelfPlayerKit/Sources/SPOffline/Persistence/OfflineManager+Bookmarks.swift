//
//  File.swift
//
//
//  Created by Rasmus Krämer on 14.04.24.
//

import Foundation
import SwiftData
import SPFoundation
import SPNetwork

// MARK: Internal (Higher order)

internal extension OfflineManager {
    func syncRemoteBookmarks() async throws {
        // isn't it really inefficient to do this instead of two queries? maybe but SwiftData does not allow it any other way
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let bookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        
        for entity in bookmarks.filter({ $0.status == .deleted }) {
            try? await AudiobookshelfClient.shared.deleteBookmark(itemId: entity.itemId, position: entity.position)
        }
        
        for entity in bookmarks.filter({ $0.status == .pending }) {
            let _ = try await AudiobookshelfClient.shared.createBookmark(itemId: entity.itemId, position: entity.position, note: entity.note)
        }
        
        // all entities will be deleted later
    }
}

// MARK: Internal (Helper)

internal extension OfflineManager {
    func syncLocalBookmarks(bookmarks: [AudiobookshelfClient.Bookmark], context: ModelContext) throws {
        for bookmark in bookmarks {
            context.insert(Bookmark(itemId: bookmark.libraryItemId, episodeId: nil, note: bookmark.title, position: bookmark.time, status: .synced))
        }
    }
    
    func deleteBookmarks(context: ModelContext) throws {
        try context.delete(model: Bookmark.self)
    }
}

// MARK: Public (Higher order)

public extension OfflineManager {
    func createBookmark(itemId: String, position: TimeInterval, note: String) async throws {
        let bookmark = try? await AudiobookshelfClient.shared.createBookmark(itemId: itemId, position: position, note: note)
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let entity: Bookmark
        
        if let bookmark {
            entity = Bookmark(itemId: bookmark.libraryItemId, episodeId: nil, note: bookmark.title, position: bookmark.time, status: .synced)
        } else {
            entity = Bookmark(itemId: itemId, episodeId: nil, note: note, position: position, status: .pending)
        }
        
        context.insert(entity)
        try context.save()
        
        NotificationCenter.default.post(name: Self.bookmarksUpdatedNotification, object: itemId)
    }
    
    func deleteBookmark(_ bookmark: Bookmark) async throws {
        do {
            try await AudiobookshelfClient.shared.deleteBookmark(itemId: bookmark.itemId, position: bookmark.position)
            
            let context = ModelContext(PersistenceManager.shared.modelContainer)
            
            context.delete(bookmark)
            try context.save()
        } catch {
            bookmark.status = Bookmark.SyncStatus.deleted
        }
        
        NotificationCenter.default.post(name: Self.bookmarksUpdatedNotification, object: bookmark.itemId)
    }
    
    func bookmarks(itemId: String) throws -> [Bookmark] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        return try context.fetch(FetchDescriptor<Bookmark>(predicate: #Predicate {
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
