//
//  BookmarkSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 18.03.25.
//

import Combine
import Foundation
import SwiftData
import OSLog

typealias PersistedBookmark = ShelfPlayerSchema.PersistedBookmark

extension PersistenceManager {
    @ModelActor
    public final actor BookmarkSubsystem {
        public final class EventSource: @unchecked Sendable {
            public let changed = PassthroughSubject<ItemIdentifier, Never>()

            init() {}
        }

        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Bookmarks")
        public nonisolated let events = EventSource()

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
            })).filter { $0.status != .deleted }
        }
        func bookmarks(connectionID: ItemIdentifier.ConnectionID) throws -> [PersistedBookmark] {
            try modelContext.fetch(FetchDescriptor<PersistedBookmark>(predicate: #Predicate {
                $0.connectionID == connectionID
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
    subscript(libraryID: LibraryIdentifier) -> [String: Int] {
        get throws {
            guard libraryID.type == .audiobooks else {
                throw PersistenceError.unsupportedItemType
            }

            return Dictionary(try bookmarks(connectionID: libraryID.connectionID).map { ($0.primaryID, 1) }, uniquingKeysWith: +)
        }
    }
    func note(at time: UInt64, for itemID: ItemIdentifier) async throws -> String {
        guard let note = try bookmark(connectionID: itemID.connectionID, primaryID: itemID.primaryID, time: time)?.note else {
            throw PersistenceError.missing
        }

        return note
    }

    func create(at time: UInt64, note: String, for itemID: ItemIdentifier) async throws {
        guard itemID.type == .audiobook else {
            throw PersistenceError.unsupportedItemType
        }

        guard try bookmark(connectionID: itemID.connectionID, primaryID: itemID.primaryID, time: time) == nil else {
            throw PersistenceError.existing
        }

        let createdOnServerAt: Date?

        do {
            createdOnServerAt = try await ABSClient[itemID.connectionID].createBookmark(primaryID: itemID.primaryID, time: time, note: note)
        } catch {
            logger.warning("Failed to create bookmark on the server for \(itemID, privacy: .public) at \(time, privacy: .public). Saving locally as pending: \(error, privacy: .public)")
            createdOnServerAt = nil
        }

        let bookmark = PersistedBookmark(connectionID: itemID.connectionID, primaryID: itemID.primaryID, time: time, note: note, created: createdOnServerAt ?? .now, status: createdOnServerAt == nil ? .pendingCreation : .synced)

        modelContext.insert(bookmark)
        try modelContext.save()

        await MainActor.run {
            events.changed.send(itemID)
        }
    }
    func update(at time: UInt64, for itemID: ItemIdentifier, note: String) async throws {
        guard let bookmark = try bookmark(connectionID: itemID.connectionID, primaryID: itemID.primaryID, time: time) else {
            throw PersistenceError.missing
        }

        bookmark.note = note

        do {
            try await ABSClient[itemID.connectionID].updateBookmark(primaryID: bookmark.primaryID, time: bookmark.time, note: bookmark.note)
            bookmark.status = .synced
        } catch {
            logger.warning("Failed to update bookmark on the server for \(itemID, privacy: .public) at \(time, privacy: .public). Saving locally as pending: \(error, privacy: .public)")
            bookmark.status = .pendingUpdate
        }

        try modelContext.save()

        await MainActor.run {
            events.changed.send(itemID)
        }
    }

    func delete(at time: UInt64, from itemID: ItemIdentifier) async throws {
        let deleteLocalBookmark: Bool

        do {
            try await ABSClient[itemID.connectionID].deleteBookmark(primaryID: itemID.primaryID, time: time)
            deleteLocalBookmark = true
        } catch {
            logger.warning("Failed to delete bookmark on the server for \(itemID, privacy: .public) at \(time, privacy: .public). Keeping local entry: \(error, privacy: .public)")
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

        await MainActor.run {
            events.changed.send(itemID)
        }
    }

    func sync(bookmarks remote: [BookmarkPayload], connectionID: ItemIdentifier.ConnectionID) async throws {
        logger.info("Synchronizing \(remote.count) bookmarks for connection \(connectionID, privacy: .public)")

        var remote = remote

        var pendingDeletion = [PersistedBookmark]()
        var pendingCreation = [PersistedBookmark]()
        var pendingUpdate = [PersistedBookmark]()

        do {
            let local = try modelContext.fetch(FetchDescriptor<PersistedBookmark>(predicate: #Predicate {
                $0.connectionID == connectionID
            }))

            for bookmark in local {
                try Task.checkCancellation()

                let time = Double(bookmark.time)

                guard let index = remote.firstIndex(where: {
                    $0.libraryItemId == bookmark.primaryID
                    && $0.time == time
                }) else {
                    if bookmark.status == .pendingCreation {
                        pendingCreation.append(bookmark)
                    } else {
                        modelContext.delete(bookmark)
                    }

                    continue
                }

                let existing = remote.remove(at: index)

                switch bookmark.status {
                case .deleted:
                    pendingDeletion.append(bookmark)
                case .pendingUpdate:
                    pendingUpdate.append(bookmark)
                default:
                    if bookmark.status == .pendingCreation {
                        logger.error("Bookmark is scheduled for creation but already exists. Updating local entity (primaryID: \(bookmark.primaryID, privacy: .public) at: \(bookmark.time) | \(bookmark.note))")
                    }

                    bookmark.note = existing.title
                    bookmark.status = .synced
                }
            }

            logger.info("Computed bookmark changes: \(pendingCreation.count) to create, \(pendingUpdate.count) to update, \(pendingDeletion.count) to delete")

            try Task.checkCancellation()

            for bookmark in remote {
                let created = Date(timeIntervalSince1970: bookmark.createdAt / 1000)
                let entity = PersistedBookmark(connectionID: connectionID, primaryID: bookmark.libraryItemId, time: UInt64(bookmark.time), note: bookmark.title, created: created, status: .synced)

                modelContext.insert(entity)
            }

            try Task.checkCancellation()

            for bookmark in pendingDeletion {
                do {
                    try await ABSClient[connectionID].deleteBookmark(primaryID: bookmark.primaryID, time: bookmark.time)
                    modelContext.delete(bookmark)
                } catch {
                    logger.error("Failed to delete bookmark with primaryID: \(bookmark.primaryID) and time: \(bookmark.time)")
                }
            }

            for bookmark in pendingUpdate {
                do {
                    try await ABSClient[connectionID].updateBookmark(primaryID: bookmark.primaryID, time: bookmark.time, note: bookmark.note)
                    bookmark.status = .synced
                } catch {
                    logger.error("Failed to update bookmark with primaryID: \(bookmark.primaryID) and time: \(bookmark.time)")
                }
            }

            for bookmark in pendingCreation {
                do {
                    let created = try await ABSClient[connectionID].createBookmark(primaryID: bookmark.primaryID, time: bookmark.time, note: bookmark.note)

                    bookmark.created = created
                    bookmark.status = .synced
                } catch {
                    logger.error("Failed to create bookmark with primaryID: \(bookmark.primaryID) and time: \(bookmark.time)")
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
