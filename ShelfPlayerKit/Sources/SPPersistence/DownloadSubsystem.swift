//
//  DownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.12.24.
//

import Foundation
import SwiftData
import OSLog
import RFNetwork
import RFNotifications
import SPFoundation
import SPNetwork

typealias PersistedAudiobook = SchemaV2.PersistedAudiobook
typealias PersistedEpisode = SchemaV2.PersistedEpisode
typealias PersistedPodcast = SchemaV2.PersistedPodcast
typealias PersistedAsset = SchemaV2.PersistedAsset

extension PersistenceManager {
    @ModelActor
    public final actor DownloadSubsystem {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "DownloadSubsystem")
        
        nonisolated(unsafe) var updateTask: Task<Void, Never>?
        
        private nonisolated lazy var urlSession: URLSession = {
            let config = URLSessionConfiguration.background(withIdentifier: "io.rfk.shelfPlayerKit.download")
            config.isDiscretionary = true
            config.sessionSendsLaunchEvents = true
            
            if ShelfPlayerKit.enableCentralized {
                config.sharedContainerIdentifier = "group.io.rfk.shelfplayer"
            }
            
            return URLSession(configuration: config, delegate: URLSessionDelegate(), delegateQueue: nil)
        }()
        
        public enum DownloadStatus: Int, Identifiable, Equatable, Codable, Hashable, Sendable, CaseIterable {
            case none
            case downloading
            case completed
            
            public var id: Int {
                rawValue
            }
        }
        
        func persistedAudiobook(for itemID: ItemIdentifier) -> PersistedAudiobook? {
            var descriptor = FetchDescriptor<PersistedAudiobook>(predicate: #Predicate {
                $0._id == itemID.description
            })
            descriptor.fetchLimit = 1
            
            return (try? modelContext.fetch(descriptor))?.first
        }
        func persistedEpisode(for itemID: ItemIdentifier) -> PersistedEpisode? {
            var descriptor = FetchDescriptor<PersistedEpisode>(predicate: #Predicate {
                $0._id == itemID.description
            })
            descriptor.fetchLimit = 1
            
            return (try? modelContext.fetch(descriptor))?.first
        }
        func persistedPodcast(for itemID: ItemIdentifier) -> PersistedPodcast? {
            var descriptor = FetchDescriptor<PersistedPodcast>(predicate: #Predicate {
                $0._id == itemID.description
            })
            descriptor.fetchLimit = 1
            
            return (try? modelContext.fetch(descriptor))?.first
        }
    }
}

extension PersistenceManager.DownloadSubsystem {
    var nextAsset: (UUID, ItemIdentifier, PersistedAsset.FileType)? {
        var descriptor = FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0.isDownloaded == false && $0.downloadTaskID == nil })
        descriptor.fetchLimit = 1
        
        guard let asset = (try? modelContext.fetch(descriptor))?.first else {
            return nil
        }
        
        return (asset.id, asset.itemID, asset.fileType)
    }
    var active: [PersistedAsset] {
        get throws {
            try modelContext.fetch(FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0.downloadTaskID != nil }))
        }
    }
    var activeTaskCount: Int {
        get throws {
            try modelContext.fetchCount(FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0.downloadTaskID != nil }))
        }
    }
    
    func downloadTask(for identifier: Int) async -> URLSessionDownloadTask? {
        await urlSession.tasks.2.first(where: { $0.taskIdentifier == identifier })
    }
    
    func assets(for itemID: ItemIdentifier) throws -> [PersistedAsset] {
        try modelContext.fetch(FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0._itemID == itemID.description }))
    }
    
    func asset(for identifier: UUID) -> PersistedAsset? {
        var descriptor = FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0.id == identifier })
        descriptor.fetchLimit = 1
        
        return (try? modelContext.fetch(descriptor))?.first
    }
    func asset(taskIdentifier: Int) -> PersistedAsset? {
        var descriptor = FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0.downloadTaskID == taskIdentifier })
        descriptor.fetchLimit = 1
        
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    func handleCompletion(taskIdentifier: Int) async {
        guard let asset = asset(taskIdentifier: taskIdentifier) else {
            assetDownloadFailed(taskIdentifier: taskIdentifier)
            return
        }
        
        let current = PersistenceManager.DownloadSubsystem.temporaryLocation(taskIdentifier: taskIdentifier)
        
        do {
            try FileManager.default.moveItem(at: current, to: asset.path)
            
            try modelContext.transaction {
                asset.downloadTaskID = nil
                asset.isDownloaded = true
            }
            try modelContext.save()
        } catch {
            assetDownloadFailed(taskIdentifier: taskIdentifier)
        }
        
        Task {
            if await status(of: asset.itemID) == .completed {
                await PersistenceManager.shared.keyValue.set(.cachedDownloadStatus(itemID: asset.itemID), .completed)
                
                let itemID = asset.itemID
                await MainActor.run {
                    RFNotification[.downloadStatusChanged].send((itemID, .completed))
                }
                
                logger.info("Cached download status for item \(asset.itemID)")
            }
        }
        
        scheduleUpdateTask()
    }
    
    func beganDownloading(assetID: UUID, taskID: Int) throws {
        guard let asset = asset(for: assetID) else {
            throw PersistenceError.missing
        }
        
        asset.downloadTaskID = taskID
        try modelContext.save()
    }
    func assetDownloadFailed(taskIdentifier: Int) {
        let destination = PersistenceManager.DownloadSubsystem.temporaryLocation(taskIdentifier: taskIdentifier)
        try? FileManager.default.removeItem(at: destination)
        
        guard let asset = asset(taskIdentifier: taskIdentifier) else {
            logger.fault("Task failed and corresponding asset not found: \(taskIdentifier)")
            PersistenceManager.shared.download.scheduleUpdateTask()
            return
        }
        
        logger.error("Task failed: \(taskIdentifier) for asset: \(asset.id)")
        
        asset.downloadTaskID = nil
        
        do {
            try modelContext.save()
        } catch {
            logger.fault("Failed to save context after task failure: \(error)")
        }
        
        let assetID = asset.id
        
        Task {
            if let failedAttempts = await PersistenceManager.shared.keyValue[.assetFailedAttempts(assetID: assetID)] {
                logger.info("Asset \(assetID) failed to download \(failedAttempts + 1) times")
                
                if failedAttempts > 3 {
                    
                } else {
                    await PersistenceManager.shared.keyValue.set(.assetFailedAttempts(assetID: assetID), failedAttempts + 1)
                }
            } else {
                await PersistenceManager.shared.keyValue.set(.assetFailedAttempts(assetID: assetID), 1)
            }
        }
        
        PersistenceManager.shared.download.scheduleUpdateTask()
    }
    func finishedDownloading(assetID: UUID) throws {
        guard let asset = asset(for: assetID) else {
            throw PersistenceError.missing
        }
        
        try finishedDownloading(asset: asset)
    }
    func finishedDownloading(asset: PersistedAsset) throws {
        if let downloadTaskID = asset.downloadTaskID {
            Task {
                if let downloadTask = await downloadTask(for: downloadTaskID) {
                    downloadTask.cancel()
                    logger.error("Marking asset as downloaded, but corresponding download task still active... Cancelling!")
                }
            }
        } else {
            logger.error("Marking asset as downloaded, but no download task ID found!")
        }
        
        asset.isDownloaded = true
        asset.downloadTaskID = nil
        
        try modelContext.save()
        
        scheduleUpdateTask()
    }
    
    func invalidateActiveDownloads() {
        logger.info("Invalidating active downloads...")
        
        guard let active = try? active else {
            return
        }
        
        for asset in active {
            asset.downloadTaskID = nil
        }
        
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save context: \(error)")
        }
    }
    
    nonisolated func scheduleUnfinishedForCompletion() async throws {
        var activeTaskCount = try await activeTaskCount
        let downloadTasks = await urlSession.tasks.2
        
        if activeTaskCount > 0 && downloadTasks.isEmpty {
            await invalidateActiveDownloads()
            activeTaskCount = 0
        }
        
        guard activeTaskCount < 2 else {
            logger.info("There are \(activeTaskCount) active downloads. Skipping...")
            return
        }
        
        guard let (id, itemID, fileType) = await nextAsset else {
            return
        }
        
        try Task.checkCancellation()
        
        let request: URLRequest
        
        switch fileType {
        case .pdf(let ino):
            request = try await ABSClient[itemID.connectionID].pdfRequest(from: itemID, ino: ino)
        case .image(let size):
            guard let coverRequest = try? await ABSClient[itemID.connectionID].coverRequest(from: itemID, width: size.width) else {
                try await finishedDownloading(assetID: id)
                return
            }
            
            request = coverRequest
        case .audio(_, _, let ino, _):
            request = try await ABSClient[itemID.connectionID].audioTrackRequest(from: itemID, ino: ino)
        }
        
        let task = urlSession.downloadTask(with: request)
        
        try await beganDownloading(assetID: id, taskID: task.taskIdentifier)
        task.resume()
        
        logger.info("Began downloading asset \(id) from item \(itemID)")
        
        Task {
            scheduleUpdateTask()
        }
    }
    
    func removeEmptyPodcasts() {
        guard let podcasts = try? modelContext.fetch(FetchDescriptor<PersistedPodcast>(predicate: #Predicate { $0.episodes.isEmpty })) else {
            return
        }
        
        for podcast in podcasts {
            modelContext.delete(podcast)
            
            let podcastID = podcast.id
            Task {
                await PersistenceManager.shared.keyValue.set(.coverURLCache(itemID: podcastID), nil)
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save after removing empty podcasts: \(error)")
        }
    }
    
    static func temporaryLocation(taskIdentifier: Int) -> URL {
        URL.temporaryDirectory.appending(path: "\(taskIdentifier).tmp")
    }
}

public extension PersistenceManager.DownloadSubsystem {
    subscript(itemID: ItemIdentifier) -> Item? {
        switch itemID.type {
        // case .audiobook:
            // persistedAudiobook(for: itemID)
        // case .episode:
            // persistedEpisode(for: itemID)
        default:
            nil
        }
    }
    
    nonisolated func scheduleUpdateTask() {
        updateTask?.cancel()
        updateTask = .detached {
            do {
                try await self.scheduleUnfinishedForCompletion()
            } catch {
                self.logger.error("Failed to schedule unfinished for completion: \(error)")
            }
        }
    }
    
    func status(of itemID: ItemIdentifier) async -> DownloadStatus {
        if let status = await PersistenceManager.shared.keyValue[.cachedDownloadStatus(itemID: itemID)] {
            return status
        }
        
        do {
            let assets = try assets(for: itemID)
            
            if assets.isEmpty {
                await PersistenceManager.shared.keyValue.set(.cachedDownloadStatus(itemID: itemID), DownloadStatus.none)
                return .none
            }
            
            let completed = assets.reduce(true) { $0 && $1.isDownloaded }
            return completed ? .completed : .downloading
        } catch {}
        
        return .none
    }
    
    func cover(for itemID: ItemIdentifier, size: ItemIdentifier.CoverSize) async -> URL? {
        if let cached = await PersistenceManager.shared.keyValue[.coverURLCache(itemID: itemID)] {
            return cached
        }
        
        guard let assets = try? assets(for: itemID) else {
            return nil
        }
        
        let asset = assets.first {
            switch $0.fileType {
            case .image(let current):
                size == current
            default:
                false
            }
        }
        let path = asset?.path
        
        guard let path else {
            return nil
        }
        
        await PersistenceManager.shared.keyValue.set(.coverURLCache(itemID: itemID), path)
        return path
    }
    
    /// Performs the necessary work to add an item to the download queue.
    ///
    /// This method is atomic and progress tracking is available after it completes.
    func download(_ itemID: ItemIdentifier) async throws {
        guard itemID.type == .audiobook || itemID.type == .episode else {
            throw PersistenceError.unsupportedDownloadItemType
        }
        
        guard persistedAudiobook(for: itemID) == nil && persistedEpisode(for: itemID) == nil else {
            throw PersistenceError.existing
        }
        
        await PersistenceManager.shared.keyValue.set(.cachedDownloadStatus(itemID: itemID), nil)
        
        // Download progress completed = all assets downloaded to 100%
        // Otherwise: 10% shared between pdfs
        // Otherwise: 10% shared between images
        // Otherwise: 80% shared between audio
        
        // Formula: category base * (1/n) where n = count of assets in category
        
        let (item, audioTracks, chapters, supplementaryPDFs) = try await ABSClient[itemID.connectionID].playableItem(itemID: itemID)
        
        var podcast: PersistedPodcast?
        
        if let episode = item as? Episode {
            podcast = persistedPodcast(for: episode.podcastID)
            
            if podcast == nil {
                let podcastItem = try await ABSClient[itemID.connectionID].podcast(with: episode.podcastID).0
                
                podcast = .init(id: podcastItem.id,
                                name: podcastItem.name,
                                authors: podcastItem.authors,
                                overview: podcastItem.description,
                                genres: podcastItem.genres,
                                addedAt: podcastItem.addedAt,
                                released: podcastItem.released,
                                explicit: podcastItem.explicit,
                                publishingType: podcastItem.publishingType,
                                episodes: [])
                
                let podcastAssets = ItemIdentifier.CoverSize.allCases.map { PersistedAsset(itemID: podcastItem.id, fileType: .image(size: $0), progressWeight: 0) }
                
                for asset in podcastAssets {
                    modelContext.insert(asset)
                }
                
                modelContext.insert(podcast!)
                try modelContext.save()
                
                logger.info("Created podcast \(podcast!.name) for episode \(episode.name)")
            }
        }
        
        var assets = [PersistedAsset]()
        
        let individualCoverWeight = 0.1 * (1 / Double(ItemIdentifier.CoverSize.allCases.count))
        let individualPDFWeight = 0.1 * (1 / Double(supplementaryPDFs.count))
        let individualAudioTrackWeight = 0.8 * (1 / Double(audioTracks.count))
        
        assets += ItemIdentifier.CoverSize.allCases.map { .init(itemID: itemID, fileType: .image(size: $0), progressWeight: individualCoverWeight) }
        assets += supplementaryPDFs.map { .init(itemID: itemID, fileType: .pdf(ino: $0.ino), progressWeight: individualPDFWeight) }
        assets += audioTracks.map { .init(itemID: itemID, fileType: .audio(offset: $0.offset, duration: $0.duration, ino: $0.ino, fileExtension: $0.fileExtension), progressWeight: individualAudioTrackWeight) }
        
        let model: any PersistentModel
        
        switch item {
        case is Audiobook:
            let audiobook = item as! Audiobook
            model = PersistedAudiobook(id: itemID,
                                       name: item.name,
                                       authors: item.authors,
                                       overview: item.description,
                                       genres: item.genres,
                                       addedAt: item.addedAt,
                                       released: item.released,
                                       size: item.size,
                                       duration: item.duration,
                                       subtitle: audiobook.subtitle,
                                       narrators: audiobook.narrators,
                                       series: audiobook.series,
                                       explicit: audiobook.explicit,
                                       abridged: audiobook.abridged)
        case is Episode:
            let episode = item as! Episode
            
            model = PersistedEpisode(id: itemID,
                                     name: item.name,
                                     authors: item.authors,
                                     overview: item.description,
                                     addedAt: item.addedAt,
                                     released: item.released,
                                     size: item.size,
                                     duration: item.duration,
                                     podcast: podcast!,
                                     index: episode.index)
            
            podcast?.episodes.append(model as! PersistedEpisode)
        default:
            fatalError("Unsupported item type: \(type(of: item))")
        }
        
        try modelContext.transaction {
            for chapter in chapters {
                modelContext.insert(SchemaV2.PersistedChapter(id: .init(), itemID: itemID, name: chapter.title, start: chapter.startOffset, end: chapter.endOffset))
            }
            
            for asset in assets {
                modelContext.insert(asset)
            }
            
            modelContext.insert(model)
        }
        try modelContext.save()
        
        logger.info("Created download for \(itemID)")
        
        await MainActor.run {
            RFNotification[.downloadStatusChanged].send((itemID, .downloading))
        }
        
        scheduleUpdateTask()
    }
    func remove(_ itemID: ItemIdentifier) async throws {
        guard itemID.type == .audiobook || itemID.type == .episode else {
            throw PersistenceError.unsupportedDownloadItemType
        }
        
        if itemID.type == .podcast {
            // TODO: this
        }
        
        let assets = try assets(for: itemID)
        
        guard !assets.isEmpty else {
            throw PersistenceError.missing
        }
        
        let tasks = await urlSession.allTasks
        
        for asset in assets {
            if asset.isDownloaded {
                try FileManager.default.removeItem(at: asset.path)
            } else if let taskID = asset.downloadTaskID {
                tasks.first(where: { $0.taskIdentifier == taskID })?.cancel()
            }
            
            await PersistenceManager.shared.keyValue.set(.assetFailedAttempts(assetID: asset.id), nil)
            modelContext.delete(asset)
        }
        
        try modelContext.delete(model: SchemaV2.PersistedChapter.self)
        
        let model: any PersistentModel = persistedAudiobook(for: itemID) ?? persistedEpisode(for: itemID)!
        modelContext.delete(model)
        
        try modelContext.save()
        
        await PersistenceManager.shared.keyValue.set(.coverURLCache(itemID: itemID), nil)
        await PersistenceManager.shared.keyValue.set(.cachedDownloadStatus(itemID: itemID), nil)
        
        await MainActor.run {
            RFNotification[.downloadStatusChanged].send((itemID, .none))
        }
        
        removeEmptyPodcasts()
    }
}

private final class URLSessionDelegate: NSObject, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destination = PersistenceManager.DownloadSubsystem.temporaryLocation(taskIdentifier: downloadTask.taskIdentifier)
        
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            PersistenceManager.shared.download.logger.error("Error moving downloaded file: \(error)")
            
            Task {
                await PersistenceManager.shared.download.assetDownloadFailed(taskIdentifier: downloadTask.taskIdentifier)
            }
            
            return
        }
        
        Task {
            await PersistenceManager.shared.download.handleCompletion(taskIdentifier: downloadTask.taskIdentifier)
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error {
            PersistenceManager.shared.download.logger.error("Download task \(task.taskIdentifier) failed: \(error)")
            
            Task {
                await PersistenceManager.shared.download.assetDownloadFailed(taskIdentifier: task.taskIdentifier)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
        Task {
            await PersistenceManager.shared.download.invalidateActiveDownloads()
        }
    }
}
