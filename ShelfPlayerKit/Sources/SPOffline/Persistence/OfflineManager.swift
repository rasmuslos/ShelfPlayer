//
//  OfflineManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import OSLog
import SPBase

public struct OfflineManager {
    public let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "OfflineProgress")
}

public extension OfflineManager {
    func authorizeAndSync() async -> Bool {
        do {
            let start = Date.timeIntervalSinceReferenceDate
            
            try await syncCachedProgressEntities()
            logger.info("Synced progress to server (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            try await deleteSyncedProgressEntities()
            logger.info("Deleted synced progress (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            try await syncRemoteBookmarks()
            logger.info("Synced bookmarks to server (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            let (progress, bookmarks) = try await AudiobookshelfClient.shared.authorize()
            
            try await updateLocalProgressEntities(mediaProgress: progress)
            logger.info("Imported sessions (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            // bookmarks don't have an id, so its more efficient to delete them instead of doing expensive queries
            try await deleteBookmarks()
            logger.info("Deleted bookmarks (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            try await syncLocalBookmarks(bookmarks: bookmarks)
            logger.info("Created bookmarks (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            return true
        } catch {
            print(error)
            return false
        }
    }
}

public extension OfflineManager {
    static let bookmarksUpdatedNotification = NSNotification.Name("io.rfk.shelfplayer.bookmarks.updated")
}

public extension OfflineManager {
    static let shared = OfflineManager()
}
