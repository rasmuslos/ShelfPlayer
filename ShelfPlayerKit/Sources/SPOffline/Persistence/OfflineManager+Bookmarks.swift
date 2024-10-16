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
        
        for entity in bookmarks.filter({ $0.status == .pendingUpdate }) {
            let _ = try? await AudiobookshelfClient.shared.updateBookmark(itemId: entity.itemId, position: entity.position, note: entity.note)
        }
        
        for entity in bookmarks.filter({ $0.status == .pendingCreation }) {
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
        guard !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OfflineError.malformed
        }
        
        let bookmark = try? await AudiobookshelfClient.shared.createBookmark(itemId: itemId, position: position, note: note)
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let entity: Bookmark
        
        if let bookmark {
            entity = Bookmark(itemId: bookmark.libraryItemId, episodeId: nil, note: bookmark.title, position: bookmark.time, status: .synced)
        } else {
            entity = Bookmark(itemId: itemId, episodeId: nil, note: note, position: position, status: .pendingCreation)
        }
        
        context.insert(entity)
        try context.save()
        
        NotificationCenter.default.post(name: Self.bookmarksUpdatedNotification, object: itemId)
    }
    
    func updateBookmark(itemId: String, position: TimeInterval, note: String) async throws {
        guard !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OfflineError.malformed
        }
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        let entity = try context.fetch(FetchDescriptor<Bookmark>(predicate: #Predicate { $0.itemId == itemId }))
            .filter { $0.status != .deleted }
            .first { $0.position == position }
        
        
        guard let entity else {
            throw OfflineError.missing
        }
        
        let bookmark = try? await AudiobookshelfClient.shared.updateBookmark(itemId: itemId, position: position, note: note)
        
        if let bookmark {
            entity.note = bookmark.title
        } else {
            entity.note = note
            entity.status = .pendingUpdate
        }
        
        try context.save()
        
        NotificationCenter.default.post(name: Self.bookmarksUpdatedNotification, object: itemId)
    }
    
    func deleteBookmark(_ bookmark: Bookmark) async throws {
        let success: Bool
        
        do {
            try await AudiobookshelfClient.shared.deleteBookmark(itemId: bookmark.itemId, position: bookmark.position)
            success = true
        } catch {
            success = false
        }
        
        // Thread safety
        // Incredibly, this fixed a bug
        guard let bookmark = try bookmarks(itemId: bookmark.itemId).first(where: { $0.position == bookmark.position }), let content = bookmark.modelContext else {
            throw OfflineError.missing
        }
        
        if success {
            content.delete(bookmark)
        } else {
            bookmark.status = .deleted
        }
        
        try content.save()
        
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
