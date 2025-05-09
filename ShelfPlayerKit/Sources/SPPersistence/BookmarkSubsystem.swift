//
//  BookmarkSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 18.03.25.
//

import Foundation
import SwiftData
import OSLog
import RFNotifications
import SPFoundation
import SPNetwork

typealias PersistedBookmark = SchemaV2.PersistedBookmark

extension PersistenceManager {
    @ModelActor
    public final actor BookmarkSubsystem {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Bookmarks")
        
        func bookmark(connectionID: ItemIdentifier.ConnectionID, primaryID: ItemIdentifier.PrimaryID, time: UInt64) throws -> PersistedBookmark? {
            try modelContext.fetch(FetchDescriptor<PersistedBookmark>(predicate: #Predicate {
                $0.connectionID == connectionID
                && $0.primaryID == primaryID
                && $0.time == time
            })).first
        }
        func bookmarks(connectionID: ItemIdentifier.ConnectionID, primaryID: ItemIdentifier.PrimaryID) throws -> [PersistedBookmark] {
            try modelContext.fetch(FetchDescriptor<PersistedBookmark>(predicate: #Predicate {
                $0.connectionID == connectionID
                && $0.primaryID == primaryID
                // && $0.status.rawValue != rawValue
            })).filter { $0.status != .deleted }
        }
        
        func remove(itemID: ItemIdentifier) {
            let primaryID = itemID.primaryID
            let connectionID = itemID.connectionID
            
            do {
                try modelContext.delete(model: PersistedBookmark.self, where: #Predicate {
                    $0.primaryID == primaryID
                    && $0.connectionID == connectionID
                })
                try modelContext.save()
            } catch {
                logger.error("Failed to remove related bookmarks to itemID \(itemID, privacy: .public): \(error)")
            }
        }
        func remove(connectionID: ItemIdentifier.ConnectionID) {
            do {
                try modelContext.delete(model: PersistedBookmark.self, where: #Predicate {
                    $0.connectionID == connectionID
                })
                try modelContext.save()
            } catch {
                logger.error("Failed to remove related bookmarks to connection \(connectionID, privacy: .public): \(error)")
            }
        }
    }
}

public extension PersistenceManager.BookmarkSubsystem {
    subscript(_ itemID: ItemIdentifier) -> [Bookmark] {
        get throws {
            guard itemID.type == .audiobook else {
                throw PersistenceError.unsupportedItemType
            }
            
            return try bookmarks(connectionID: itemID.connectionID, primaryID: itemID.primaryID).map { Bookmark(itemID: itemID, time: $0.time, note: $0.note, created: $0.created) }
        }
    }
    
    func create(at time: UInt64, note: String, for itemID: ItemIdentifier) async throws {
        guard try bookmark(connectionID: itemID.connectionID, primaryID: itemID.primaryID, time: time) == nil else {
            throw PersistenceError.existing
        }
        
        let createdOnServerAt: Date?
        
        do {
            createdOnServerAt = try await ABSClient[itemID.connectionID].createBookmark(primaryID: itemID.primaryID, time: time, note: note)
        } catch {
            createdOnServerAt = nil
        }
        
        let bookmark = PersistedBookmark(connectionID: itemID.connectionID, primaryID: itemID.primaryID, time: time, note: note, created: createdOnServerAt ?? .now, status: createdOnServerAt == nil ? .pendingCreation : .synced)
        
        modelContext.insert(bookmark)
        try modelContext.save()
        
        await RFNotification[.bookmarksChanged].send(payload: itemID)
    }
    
    func delete(at time: UInt64, from itemID: ItemIdentifier) async throws {
        let deleteLocalBookmark: Bool
        
        do {
            try await ABSClient[itemID.connectionID].deleteBookmark(primaryID: itemID.primaryID, time: time)
            deleteLocalBookmark = true
        } catch {
            deleteLocalBookmark = false
        }
        
        guard let bookmark = try bookmark(connectionID: itemID.connectionID, primaryID: itemID.primaryID, time: time) else {
            logger.error("Tried to delete a non existent bookmark at \(time) for item \(itemID, privacy: .public)")
            throw PersistenceError.missing
        }
        
        if deleteLocalBookmark {
            modelContext.delete(bookmark)
        } else {
            bookmark.status = .deleted
        }
        
        try modelContext.save()
        
        await RFNotification[.bookmarksChanged].send(payload: itemID)
    }
    
    func sync(bookmarks: [BookmarkPayload], connectionID: ItemIdentifier.ConnectionID) async throws {
        logger.info("Syncronizing \(bookmarks.count) bookmarks for connection \(connectionID, privacy: .public)")
        
        var bookmarks = bookmarks
        
        var pendingDeletion = [(primaryID: ItemIdentifier.PrimaryID, time: UInt64)]()
        var pendingCreation = [(primaryID: ItemIdentifier.PrimaryID, time: UInt64, note: String)]()
        var pendingUpdate = [(primaryID: ItemIdentifier.PrimaryID, time: UInt64, note: String)]()
        
        try modelContext.save()
        
        do {
            try modelContext.transaction {
                try modelContext.enumerate(FetchDescriptor<PersistedBookmark>(predicate: #Predicate {
                    $0.connectionID == connectionID
                })) { bookmark in
                    try Task.checkCancellation()
                    
                    let time = Double(bookmark.time)
                    
                    guard let index = bookmarks.firstIndex(where: {
                        $0.libraryItemId == bookmark.primaryID
                        && $0.time == time
                    }) else {
                        if bookmark.status == .pendingCreation {
                            pendingCreation.append((bookmark.primaryID, bookmark.time, bookmark.note))
                        } else {
                            modelContext.delete(bookmark)
                        }
                        
                        return
                    }
                    
                    let existing = bookmarks.remove(at: index)
                    
                    switch bookmark.status {
                    case .deleted:
                        pendingDeletion.append((bookmark.primaryID, bookmark.time))
                        modelContext.delete(bookmark)
                    case .pendingUpdate:
                        pendingUpdate.append((bookmark.primaryID, bookmark.time, bookmark.note))
                        bookmark.status = .synced
                    default:
                        if bookmark.status == .pendingCreation {
                            logger.error("Bookmark is scheduled for creation but already exists. Updating local entity (primaryID: \(bookmark.primaryID, privacy: .public) at: \(bookmark.time) | \(bookmark.note))")
                        }
                        
                        bookmark.note = existing.title
                        bookmark.status = .synced
                    }
                }
            }
            
            try Task.checkCancellation()
            
            for bookmark in bookmarks {
                let created = Date(timeIntervalSince1970: bookmark.createdAt / 1000)
                let entity = PersistedBookmark(connectionID: connectionID, primaryID: bookmark.libraryItemId, time: UInt64(bookmark.time), note: bookmark.title, created: created, status: .synced)
                
                modelContext.insert(entity)
            }
            
            try Task.checkCancellation()
            
            for (primaryID, time) in pendingDeletion {
                try await ABSClient[connectionID].deleteBookmark(primaryID: primaryID, time: time)
            }
            
            for (primaryID, time, note) in pendingUpdate {
                try await ABSClient[connectionID].updateBookmark(primaryID: primaryID, time: time, note: note)
            }
            
            for (primaryID, time, note) in pendingCreation {
                let created = try await ABSClient[connectionID].createBookmark(primaryID: primaryID, time: time, note: note)
                
                if let bookmark = try modelContext.fetch(FetchDescriptor<PersistedBookmark>(predicate: #Predicate {
                    $0.connectionID == connectionID
                    && $0.primaryID == primaryID
                    && $0.time == time
                })).first {
                    bookmark.created = created
                }
            }
            
            try modelContext.save()
        } catch {
            logger.error("Error while syncing bookmarks: \(error)")
            
            modelContext.rollback()
            try modelContext.save()
            
            throw error
        }
    }
}
