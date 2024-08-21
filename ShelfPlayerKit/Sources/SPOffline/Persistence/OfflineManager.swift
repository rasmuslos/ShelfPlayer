//
//  OfflineManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData
import OSLog
import SPFoundation
import SPNetwork

public struct OfflineManager {
    public let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "OfflineProgress")
}

public extension OfflineManager {
    func authorizeAndSync() async -> Bool {
        do {
            let start = Date.timeIntervalSinceReferenceDate
            
            try await syncRemoteBookmarks()
            logger.info("Synced bookmarks to server (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            try await syncCachedProgressEntities()
            logger.info("Synced progress to server (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            let (progress, bookmarks) = try await AudiobookshelfClient.shared.authorize()
            
            // No context switches after this point
            let context = ModelContext(PersistenceManager.shared.modelContainer)
            // Do not make any changes to the database unless all of the following methods succeed
            context.autosaveEnabled = false
            
            try deleteProgressEntities(type: .localSynced, context: context)
            logger.info("Deleted synced progress (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            try updateLocalProgressEntities(mediaProgress: progress, context: context)
            logger.info("Imported sessions (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            // Bookmarks don't have an id, so its more efficient to delete them instead of doing expensive queries
            try deleteBookmarks(context: context)
            logger.info("Deleted bookmarks (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            try syncLocalBookmarks(bookmarks: bookmarks, context: context)
            logger.info("Created bookmarks (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            // Commit changes
            try context.save()
            
            return true
        } catch {
            logger.fault("Error while syncing progress & bookmarks. Changes will not be committed...")
            print(error)
            
            return false
        }
    }
}

public extension OfflineManager {
    enum OfflineError: Error {
        case existing
        case missing
        case fetchFailed
    }
}

public extension OfflineManager {
    static let bookmarksUpdatedNotification = NSNotification.Name("io.rfk.shelfplayer.bookmarks.updated")
    static let downloadProgressUpdatedNotification = NSNotification.Name("io.rfk.shelfplayer.download.progress")
}

public extension OfflineManager {
    static let shared = OfflineManager()
}
