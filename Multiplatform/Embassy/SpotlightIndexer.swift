//
//  SpotlightIndex.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.05.25.
//

import Foundation
@preconcurrency import CoreSpotlight
@preconcurrency import BackgroundTasks
import Network
import OSLog
import ShelfPlayback

final actor SpotlightIndexer: Sendable {
    static let BACKGROUND_TASK_IDENTIFIER = "io.rfk.shelfPlayer.spotlightIndex"
    
    let logger = Logger(subsystem: "io.rfk.ShelfPlayer", category: "SpotlightIndexer")
    
    private(set) var isRunning = false
    private nonisolated(unsafe) var shouldComeToEnd = false
    
    let index = CSSearchableIndex(name: "ShelfPlayer-Items", protectionClass: .completeUntilFirstUserAuthentication)
    
    nonisolated func scheduleBackgroundTask() async {
        guard await BGTaskScheduler.shared.pendingTaskRequests().first(where: {$0.identifier == Self.BACKGROUND_TASK_IDENTIFIER }) == nil else {
            logger.warning("Requested background task even though it is already scheduled")
            return
        }
        
        let request = BGProcessingTaskRequest(identifier: Self.BACKGROUND_TASK_IDENTIFIER)
        request.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled background task: \(request)")
        } catch {
            logger.error("Failed to schedule background task: \(error)")
        }
    }
    
    nonisolated func handleBackgroundTask(_ task: BGTask) {
        task.expirationHandler = {
            self.logger.info("Expiration handler called on background task for identifier: \(task.identifier)")
            self.shouldComeToEnd = true
        }
        
        // Detect finish
        
        Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(0.2))
                
                guard await !isRunning else {
                    continue
                }
                
                task.setTaskCompleted(success: true)
                logger.info("Finished Spotlight indexing task")
                
                break
            }
        }
        
        // Schedule task
        
        run()
    }
    
    nonisolated func run() {
        Task {
            guard await shouldRun() else {
                return
            }
            
            var shouldContinue = !shouldComeToEnd
            
            do {
                var (libraries, metadata) = try await planRun()
                
                while shouldContinue {
                    let isFinished = try await iteration(libraries: libraries, metadata: &metadata)
                    shouldContinue = !shouldComeToEnd && isFinished
                }
            } catch {
                logger.error("Encountered error while running SpotlightIndexer: \(error)")
            }
            
            await endRun()
        }
    }
    
    nonisolated func reset() async throws {
        Defaults[.spotlightIndexCompletionDate] = nil
        
        try await index.deleteAllSearchableItems()
        
        try await PersistenceManager.shared.keyValue.remove(cluster: "libraryIndexedIDs")
        try await PersistenceManager.shared.keyValue.remove(cluster: "libraryIndexMetadata")
    }
    
    static let shared = SpotlightIndexer()
}

private extension SpotlightIndexer {
    func shouldRun() -> Bool {
        let path = NWPathMonitor().currentPath
        
        guard !path.isExpensive && !path.isConstrained else {
            return false
        }
        
        guard !isRunning else {
            logger.warning("Tried to run SpotlightIndexer while it was already running.")
            return false
        }
        
        isRunning = true
        return true
    }
    func endRun() {
        isRunning = false
    }
    
    func iteration(libraries: [Library], metadata: inout [Library: PersistenceManager.ItemSubsystem.LibraryIndexMetadata]) async throws -> Bool {
        let candidates = metadata.compactMap { $1.isFinished ? nil : $0 } + libraries.filter { !metadata.keys.contains($0) }
        
        guard let next = candidates.first else {
            logger.info("Spotlight Indexer finished.")
            
            if Defaults[.spotlightIndexCompletionDate] == nil {
                Defaults[.spotlightIndexCompletionDate] = .now
            }
            
            return false
        }
        
        Defaults[.spotlightIndexCompletionDate] = nil
        
        if metadata[next] == nil {
            metadata[next] = .init()
        }
        
        try await indexLibrary(library: next, metadata: &metadata[next]!)
        
        return true
    }
    
    nonisolated func planRun() async throws -> ([Library], [Library: PersistenceManager.ItemSubsystem.LibraryIndexMetadata]) {
        let validForSeconds: Double = 60 * 60 * 24 * 21
        
        let libraries = await ShelfPlayerKit.libraries
        
        return (libraries, await withTaskGroup {
            for library in libraries {
                $0.addTask { () -> (Library, PersistenceManager.ItemSubsystem.LibraryIndexMetadata?) in
                    let metadata = await PersistenceManager.shared.item.libraryIndexMetadata(for: library)
                    
                    if let distance = metadata?.endDate?.distance(to: .now), distance > validForSeconds {
                        self.logger.info("Reindexing \(library.name) because its metadata is expired.")
                        return (library, nil)
                    }
                    
                    return (library, metadata)
                }
            }
            
            return await $0.reduce(into: [:]) {
                $0[$1.0] = $1.1
            }
        })
    }
    func indexLibrary(library: Library, metadata: inout PersistenceManager.ItemSubsystem.LibraryIndexMetadata) async throws {
        let PAGE_SIZE = 100
        
        let total: Int
        let isFinished: Bool
        let attributes: [(ItemIdentifier, CSSearchableItemAttributeSet)]
        
        switch library.type {
            case .audiobooks:
                let sections: [AudiobookSection]
                (sections, total) = try await ABSClient[library.connectionID].audiobooks(from: library.id, filter: .all, sortOrder: .added, ascending: true, limit: PAGE_SIZE, page: metadata.page)
                
                isFinished = sections.isEmpty
                attributes = await withTaskGroup {
                    for audiobook in sections.compactMap(\.audiobook) {
                        $0.addTask {
                            let attributes = CSSearchableItemAttributeSet(contentType: .audio)
                            
                            attributes.identifier = audiobook.id.description
                            
                            attributes.displayName = audiobook.name
                            attributes.thumbnailData = await audiobook.id.data(size: .small)
                            attributes.title = audiobook.name
                            
                            attributes.userCreated = audiobook.addedAt.timeIntervalSince1970 as NSNumber
                            attributes.contentCreationDate = audiobook.addedAt
                            attributes.addedDate = audiobook.addedAt
                            
                            attributes.duration = audiobook.duration as NSNumber
                            attributes.streamable = 1
                            
                            attributes.genre = audiobook.genres.formatted(.list(type: .and))
                            attributes.information = audiobook.description
                            attributes.url = try? await audiobook.id.url
                            
                            attributes.artist = audiobook.authors.formatted(.list(type: .and))
                            
                            return (audiobook.id, attributes)
                        }
                    }
                    
                    return await $0.reduce(into: []) {
                        $0.append($1)
                    }
                }
            case .podcasts:
                let podcasts: [Podcast]
                (podcasts, total) = try await ABSClient[library.connectionID].podcasts(from: library.id, sortOrder: .addedAt, ascending: true, limit: PAGE_SIZE, page: metadata.page)
                
                isFinished = podcasts.isEmpty
                attributes = await withTaskGroup {
                    for podcast in podcasts {
                        $0.addTask {
                            let attributes = CSSearchableItemAttributeSet(contentType: .audio)
                            
                            attributes.identifier = podcast.id.description
                            
                            attributes.displayName = podcast.name
                            attributes.thumbnailData = await podcast.id.data(size: .small)
                            attributes.title = podcast.name
                            
                            attributes.userCreated = NSNumber(value: podcast.addedAt.timeIntervalSince1970)
                            attributes.contentCreationDate = podcast.addedAt
                            attributes.addedDate = podcast.addedAt
                            
                            attributes.genre = podcast.genres.formatted(.list(type: .and))
                            attributes.information = podcast.description
                            attributes.url = try? await podcast.id.url
                            
                            attributes.artist = podcast.authors.formatted(.list(type: .and))
                            
                            return (podcast.id, attributes)
                        }
                    }
                    
                    return await $0.reduce(into: []) {
                        $0.append($1)
                    }
                }
        }
        
        let items = attributes.map { CSSearchableItem(uniqueIdentifier: $0.description, domainIdentifier: "shelfPlayer-item-\(library.id)^\(library.connectionID)", attributeSet: $1) }
        try await index.indexSearchableItems(items)
        
        let currentlyIndexed = await PersistenceManager.shared.item.libraryIndexedIDs(for: library, subset: "current") + attributes.map(\.0)
        try await PersistenceManager.shared.item.setLibraryIndexedIDs(currentlyIndexed, for: library, subset: "current")
        
        if metadata.startDate == nil {
            metadata.startDate = .now
        }
        
        if isFinished {
            metadata.endDate = .now
            
            let previouslyIndexed = await PersistenceManager.shared.item.libraryIndexedIDs(for: library, subset: "previous")
            
            let orphaned = previouslyIndexed.filter { !currentlyIndexed.contains($0) }
            try await index.deleteSearchableItems(withIdentifiers: orphaned.map(\.description))
            
            for orphan in orphaned {
                await PersistenceManager.shared.remove(itemID: orphan)
            }
            
            try await PersistenceManager.shared.item.setLibraryIndexedIDs(currentlyIndexed, for: library, subset: "previous")
            
            logger.info("Finished indexing library \(library.id) (\(library.connectionID)). \(items.count)/\(total) items indexed. \(orphaned.count) orphaned items deleted.")
        } else {
            metadata.page += 1
        }
        
        if metadata.totalItemCount == nil {
            metadata.totalItemCount = total
        } else if metadata.totalItemCount != total {
            metadata.page = 0
        }
        
        try await PersistenceManager.shared.item.setLibraryIndexMetadata(metadata, for: library)
        
        logger.info("Indexed \(items.count)/\(total) for library \(library.id) (\(library.connectionID)).")
    }
}

extension CSSearchableItem: @retroactive @unchecked Sendable {}
