//
//  DownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.12.24.
//

import Combine
import Foundation
import SwiftData
import OSLog
import Network

#if canImport(UIKit)
import UIKit
#endif

typealias PersistedAudiobook = ShelfPlayerSchema.PersistedAudiobook
typealias PersistedEpisode = ShelfPlayerSchema.PersistedEpisode
typealias PersistedPodcast = ShelfPlayerSchema.PersistedPodcast

typealias PersistedAsset = ShelfPlayerSchema.PersistedAsset
typealias PersistedChapter = ShelfPlayerSchema.PersistedChapter

private let ASSET_ATTEMPT_LIMIT = 3
private let ACTIVE_TASK_LIMIT = 4

extension PersistenceManager {
    @ModelActor
    public final actor DownloadSubsystem {
        public final class EventSource: @unchecked Sendable {
            public typealias ProgressPayload = (itemID: ItemIdentifier, assetID: UUID, weight: Percentage, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)

            public let statusChanged = PassthroughSubject<(itemID: ItemIdentifier, status: DownloadStatus)?, Never>()
            public let progressChanged = PassthroughSubject<ProgressPayload, Never>()

            init() {}
        }

        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Download")
        public nonisolated let events = EventSource()

        var blocked = [ItemIdentifier: Int]()
        var busy = Set<ItemIdentifier>()

        var updateTask: Task<Void, Never>?

        // In-memory caches replacing key-value store
        var downloadStatusCache = [ItemIdentifier: DownloadStatus]()
        var assetFailedAttempts = [UUID: Int]()
        var coverURLCache = [String: URL]()

        private lazy var urlSession: URLSession = {
            let config = URLSessionConfiguration.background(withIdentifier: "io.rfk.shelfPlayerKit.download")

            config.sessionSendsLaunchEvents = true
            config.waitsForConnectivity = true

            config.timeoutIntervalForRequest = 120

            config.httpCookieStorage = ShelfPlayerKit.httpCookieStorage
            config.httpShouldSetCookies = true
            config.httpCookieAcceptPolicy = .onlyFromMainDocumentDomain

            if ShelfPlayerKit.enableCentralized {
                config.sharedContainerIdentifier = ShelfPlayerKit.groupContainer
            }

            return URLSession(configuration: config, delegate: URLSessionDelegate(), delegateQueue: nil)
        }()

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

        func remove(connectionID: ItemIdentifier.ConnectionID) async {
            logger.info("Removing downloads related to connection \(connectionID, privacy: .public)")

            do {
                try modelContext.delete(model: PersistedAudiobook.self, where: #Predicate { $0._id.contains(connectionID) })

                for podcast in try podcasts() {
                    do {
                        try await remove(podcast.id)
                    } catch {
                        logger.warning("Failure removing podcast download for connection \(connectionID, privacy: .public) podcast \(podcast.id, privacy: .public): \(error, privacy: .public)")
                    }
                }
            } catch {
                logger.warning("Failed to remove audiobook downloads for connection \(connectionID, privacy: .public): \(error, privacy: .public)")
            }

            do {
                try modelContext.delete(model: PersistedAsset.self, where: #Predicate { $0._itemID.contains(connectionID) })
                try modelContext.delete(model: PersistedChapter.self, where: #Predicate { $0._itemID.contains(connectionID) })
            } catch {
                logger.warning("Failed to remove assets/chapters for connection \(connectionID, privacy: .public): \(error, privacy: .public)")
            }

            do {
                let path = ShelfPlayerKit.downloadDirectoryURL.appending(path: connectionID.urlSafe)
                try FileManager.default.removeItem(at: path)
            } catch {
                logger.warning("Failed to remove download directory for connection \(connectionID, privacy: .public): \(error, privacy: .public)")
            }

            Task { @MainActor in
                self.events.statusChanged.send(nil)
            }
        }
    }
}

private extension PersistenceManager.DownloadSubsystem {
    var nextAsset: (UUID, ItemIdentifier, PersistedAsset.FileType)? {
        var descriptor = FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0.isDownloaded == false && $0.downloadTaskID == nil })
        descriptor.fetchLimit = 1

        guard let asset = (try? modelContext.fetch(descriptor))?.first else {
            return nil
        }

        return (asset.id, asset.itemID, asset.fileType)
    }

    func downloadTask(for identifier: Int) async -> URLSessionDownloadTask? {
        await urlSession.tasks.2.first(where: { $0.taskIdentifier == identifier })
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

    func assets(for itemID: ItemIdentifier) throws -> [PersistedAsset] {
        try modelContext.fetch(FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0._itemID == itemID.description }))
    }
    func removeAssets(_ assets: [PersistedAsset]) async throws {
        let tasks = await urlSession.allTasks

        for asset in assets {
            if asset.isDownloaded {
                do {
                    try FileManager.default.removeItem(at: asset.path)
                } catch {
                    logger.warning("Failed to remove downloaded asset file \(asset.id, privacy: .public) for \(asset.itemID, privacy: .public): \(error, privacy: .public)")
                }
            } else if let taskID = asset.downloadTaskID {
                tasks.first(where: { $0.taskIdentifier == taskID })?.cancel()
            }

            modelContext.delete(asset)
        }
    }

    func fetchDownloadStatus(of itemID: ItemIdentifier) -> DownloadStatus {
        do {
            let assets = try assets(for: itemID)

            if assets.isEmpty {
                return .none
            }

            let completed = assets.reduce(true) { $0 && $1.isDownloaded }
            return completed ? .completed : .downloading
        } catch {
            logger.warning("Failed to fetch download status for \(itemID, privacy: .public): \(error, privacy: .public)")
            return .none
        }
    }

    func handleCompletion(taskIdentifier: Int) async {
        guard let asset = asset(taskIdentifier: taskIdentifier) else {
            assetDownloadFailed(taskIdentifier: taskIdentifier)
            return
        }

        let current = PersistenceManager.DownloadSubsystem.temporaryLocation(taskIdentifier: taskIdentifier)

        do {
            var target = asset.path
            try FileManager.default.moveItem(at: current, to: target)

            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true

            try target.setResourceValues(resourceValues)

            try finishedDownloading(asset: asset)
        } catch {
            logger.warning("Failed to finalize download task \(taskIdentifier, privacy: .public): \(error, privacy: .public)")
            assetDownloadFailed(taskIdentifier: taskIdentifier)
        }
    }

    func reportProgress(taskID: Int, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let asset = asset(taskIdentifier: taskID) else {
            return
        }

        let id = asset.id
        let itemID = asset.itemID
        let progressWeight = asset.progressWeight

        Task {
            await MainActor.run {
                self.events.progressChanged.send((itemID, id, progressWeight, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite))
            }
        }
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
        do {
            try FileManager.default.removeItem(at: destination)
        } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
            // expected: temp file may not exist
        } catch {
            logger.warning("Failed to remove temporary download file for task \(taskIdentifier, privacy: .public): \(error, privacy: .public)")
        }

        guard let asset = asset(taskIdentifier: taskIdentifier) else {
            logger.fault("Task failed and corresponding asset not found: \(taskIdentifier)")

            Task {
                await PersistenceManager.shared.download.scheduleUpdateTask()
            }
            return
        }

        logger.error("Task failed: \(taskIdentifier, privacy: .public) for asset: \(asset.id, privacy: .public)")

        asset.downloadTaskID = nil

        do {
            try modelContext.save()
        } catch {
            logger.fault("Failed to save context after task failure: \(error)")
        }

        let assetID = asset.id
        let assetItemID = asset.itemID

        Task {
            let failedAttempts = await PersistenceManager.shared.download.assetFailedAttempts[assetID] ?? 0

            logger.info("Asset \(assetID, privacy: .public) failed to download \(failedAttempts + 1) times")

            if failedAttempts > ASSET_ATTEMPT_LIMIT {
                logger.warning("Asset \(assetID, privacy: .public) failed to download more than 3 times. Removing download \(assetItemID, privacy: .public)")
                do {
                    try await PersistenceManager.shared.download.remove(assetItemID)
                } catch {
                    logger.warning("Failed to remove download \(assetItemID, privacy: .public) after exceeding attempt limit: \(error, privacy: .public)")
                }
            } else {
                await PersistenceManager.shared.download.setAssetFailedAttempts(assetID, count: failedAttempts + 1)
            }

            await PersistenceManager.shared.download.scheduleUpdateTask()
        }
    }

    func setAssetFailedAttempts(_ assetID: UUID, count: Int) {
        assetFailedAttempts[assetID] = count
    }

    func finishedDownloading(assetID: UUID) throws {
        guard let asset = asset(for: assetID) else {
            throw PersistenceError.missing
        }

        try finishedDownloading(asset: asset)
    }
    func finishedDownloading(asset: PersistedAsset) throws {
        asset.isDownloaded = true
        asset.downloadTaskID = nil

        try modelContext.save()

        logger.info("Finished downloading asset \(asset.id, privacy: .public) for \(asset.itemID, privacy: .public)")

        if fetchDownloadStatus(of: asset.itemID) == .completed {
            Task {
                await finishedDownloading(itemID: asset.itemID)
            }
        }

        scheduleUpdateTask()
    }
    func finishedDownloading(itemID: ItemIdentifier) async {
        downloadStatusCache[itemID] = .completed

        await MainActor.run {
            events.statusChanged.send((itemID, .completed))
        }
    }

    nonisolated func scheduleUnfinishedForCompletion() async throws {
        let path = NWPathMonitor().currentPath

        if (path.isExpensive || path.isConstrained) && !AppSettings.shared.allowCellularDownloads {
            return
        }

        let tasks = await urlSession.tasks.2

        guard tasks.count < ACTIVE_TASK_LIMIT else {
            logger.info("There are \(tasks.count) active downloads. Skipping.")
            return
        }

        guard let (id, itemID, fileType) = await nextAsset else {
            return
        }

        try Task.checkCancellation()

        let request: URLRequest

        switch fileType {
        case .pdf(_, let ino):
            let apiRequest = try await ABSClient[itemID.connectionID].pdfRequest(from: itemID, ino: ino)
            request = try await ABSClient[itemID.connectionID].request(apiRequest)
        case .image(let size):
            guard let apiRequest = try? await ABSClient[itemID.connectionID].coverRequest(from: itemID, width: size.width),
                  let coverRequest = try? await ABSClient[itemID.connectionID].request(apiRequest) else {
                try await finishedDownloading(assetID: id)
                await scheduleUpdateTask()

                return
            }

            request = coverRequest
        case .audio(_, _, let ino, _):
            request = try await ABSClient[itemID.connectionID].audioTrackRequest(from: itemID, ino: ino)
        }

        let task = await urlSession.downloadTask(with: request)

        try await beganDownloading(assetID: id, taskID: task.taskIdentifier)
        task.resume()

        logger.info("Began downloading asset \(id) from item \(itemID)")

        await scheduleUpdateTask()
    }

    func removeEmptyPodcasts() async throws {
        guard let podcasts = try? modelContext.fetch(FetchDescriptor<PersistedPodcast>(predicate: #Predicate { $0.episodes.isEmpty })) else {
            return
        }

        for podcast in podcasts {
            try await remove(podcast.id)
        }
    }

    static func temporaryLocation(taskIdentifier: Int) -> URL {
        URL.temporaryDirectory.appending(path: "\(taskIdentifier).tmp")
    }
}

public extension PersistenceManager.DownloadSubsystem {
    var totalCount: Int {
        let audiobookCount = try? modelContext.fetchCount(FetchDescriptor<PersistedAudiobook>())
        let episodeCount = try? modelContext.fetchCount(FetchDescriptor<PersistedEpisode>())

        return (audiobookCount ?? 0) + (episodeCount ?? 0)
    }

    subscript(itemID: ItemIdentifier) -> Item? {
        switch itemID.type {
        case .audiobook:
            if let audiobook = persistedAudiobook(for: itemID) {
                return Audiobook(downloaded: audiobook)
            }
        case .episode:
            if let episode = persistedEpisode(for: itemID) {
                return Episode(downloaded: episode)
            }

        case .podcast:
            if let podcast = persistedPodcast(for: itemID) {
                return Podcast(downloaded: podcast)
            }
        default:
            break
        }

        return nil
    }
    func item(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> PlayableItem? {
        if let groupingID {
            let episodeType = ItemIdentifier.ItemType.episode.rawValue
            var episodeDescriptor = FetchDescriptor<PersistedEpisode>(predicate: #Predicate {
                $0._id.contains(primaryID)
                && $0._id.contains(groupingID)
                && $0._id.contains(connectionID)
                && $0._id.contains(episodeType)
            })
            episodeDescriptor.fetchLimit = 1

            guard let episode = (try? modelContext.fetch(episodeDescriptor))?.first else {
                return nil
            }

            return Episode(downloaded: episode)
        } else {
            let audiobookType = ItemIdentifier.ItemType.audiobook.rawValue
            var audiobookDescriptor = FetchDescriptor<PersistedAudiobook>(predicate: #Predicate {
                $0._id.contains(primaryID)
                && $0._id.contains(connectionID)
                && $0._id.contains(audiobookType)
            })
            audiobookDescriptor.fetchLimit = 1

            guard let audiobook = (try? modelContext.fetch(audiobookDescriptor))?.first else {
                return nil
            }

            return Audiobook(downloaded: audiobook)
        }
    }
    func podcast(primaryID: ItemIdentifier.PrimaryID, connectionID: ItemIdentifier.ConnectionID) -> Podcast? {
        let podcastType = ItemIdentifier.ItemType.podcast.rawValue

        var descriptor = FetchDescriptor<PersistedPodcast>(predicate: #Predicate {
            $0._id.contains(primaryID)
            && $0._id.contains(connectionID)
            && $0._id.contains(podcastType)
        })
        descriptor.fetchLimit = 1

        guard let podcast = (try? modelContext.fetch(descriptor))?.first else {
            return nil
        }

        return .init(downloaded: podcast)
    }

    func scheduleUpdateTask() {
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
        guard itemID.isPlayable else {
            return .none
        }

        if let cached = downloadStatusCache[itemID] {
            if cached == .none {
                downloadStatusCache.removeValue(forKey: itemID)
            } else {
                return cached
            }
        }

        logger.warning("Download status for \(itemID) is not cached, fetching again.")

        let status = fetchDownloadStatus(of: itemID)
        downloadStatusCache[itemID] = status

        return status
    }

    func downloadProgress(of itemID: ItemIdentifier) -> Percentage {
        (try? assets(for: itemID).filter { $0.isDownloaded }.reduce(0) { $0 + $1.progressWeight }) ?? 0
    }

    func cover(for itemID: ItemIdentifier, size: ImageSize) async -> URL? {
        let cacheKey = "\(itemID)_\(size)"

        if let cached = coverURLCache[cacheKey] {
            if FileManager.default.fileExists(atPath: cached.path()) {
                return cached
            } else {
                return nil
            }
        }

        guard let assets = try? assets(for: itemID) else {
            return nil
        }

        let asset = assets.first {
            switch $0.fileType {
            case .image(let current): size == current
            default: false
            }
        }

        let path = asset?.path

        guard let path, FileManager.default.fileExists(atPath: path.path()) else {
            return nil
        }

        coverURLCache[cacheKey] = path

        return path
    }
    func audioTracks(for itemID: ItemIdentifier) throws -> [PlayableItem.AudioTrack] {
        try assets(for: itemID).compactMap {
            switch $0.fileType {
            case .audio(let offset, let duration, _, _): .init(offset: offset, duration: duration, resource: $0.path)
            default: nil
            }
        }
    }
    func chapters(itemID: ItemIdentifier) -> [Chapter] {
        do {
            return try modelContext.fetch(FetchDescriptor<PersistedChapter>(predicate: #Predicate {
                $0._itemID == itemID.description
            })).map { .init(id: $0.index, startOffset: $0.startOffset, endOffset: $0.endOffset, title: $0.name) }
        } catch {
            logger.warning("Failed to fetch persisted chapters for \(itemID, privacy: .public): \(error, privacy: .public)")
            return []
        }
    }

    func audiobooks() throws -> [Audiobook] {
        return try modelContext.fetch(FetchDescriptor<PersistedAudiobook>()).map(Audiobook.init)
    }
    func audiobooks(in libraryID: String) throws -> [Audiobook] {
        try modelContext.fetch(FetchDescriptor<PersistedAudiobook>())
            .filter { $0.id.libraryID == libraryID }
            .map(Audiobook.init)
    }

    func episodes() throws -> [Episode] {
        try modelContext.fetch(FetchDescriptor<PersistedEpisode>()).map(Episode.init)
    }
    func episodes(from podcastID: ItemIdentifier) throws -> [Episode] {
        guard podcastID.type == .podcast else {
            throw PersistenceError.unsupportedItemType
        }

        guard let podcast = persistedPodcast(for: podcastID) else {
            return []
        }

        return podcast.episodes.map(Episode.init)
    }
    func episodes(in libraryID: ItemIdentifier.LibraryID) throws -> [Episode] {
        try modelContext.fetch(FetchDescriptor<PersistedEpisode>())
            .filter { $0.id.libraryID == libraryID }
            .map(Episode.init)
    }

    func podcasts() throws -> [Podcast] {
        try modelContext.fetch(FetchDescriptor<PersistedPodcast>()).map(Podcast.init)
    }

    func download(_ itemID: ItemIdentifier) async throws {
        guard itemID.isPlayable else {
            throw PersistenceError.unsupportedItemType
        }

        guard await PersistenceManager.shared.authorization.canDownload(for: itemID.connectionID) else {
            throw PersistenceError.notPermitted
        }

        guard persistedAudiobook(for: itemID) == nil && persistedEpisode(for: itemID) == nil else {
            if downloadStatusCache[itemID] == Optional<DownloadStatus>.none {
                let status = await status(of: itemID)

                downloadStatusCache[itemID] = status
                await MainActor.run {
                    events.statusChanged.send((itemID, status))
                }
            }

            throw PersistenceError.existing
        }

        guard !blocked.keys.contains(itemID) else {
            throw PersistenceError.blocked
        }

        guard !busy.contains(itemID) else {
            throw PersistenceError.busy
        }

        busy.insert(itemID)

        let task = await UIApplication.shared.beginBackgroundTask(withName: "download::\(itemID)")

        do {
            downloadStatusCache.removeValue(forKey: itemID)

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
                                    totalEpisodeCount: podcastItem.episodeCount,
                                    episodes: [])

                    let podcastAssets = ImageSize.allCases.map { PersistedAsset(itemID: podcastItem.id, fileType: .image(size: $0), progressWeight: 0) }

                    for asset in podcastAssets {
                        modelContext.insert(asset)
                    }

                    modelContext.insert(podcast!)
                    try modelContext.save()

                    logger.info("Created podcast \(podcast!.name) for episode \(episode.name)")
                }
            }

            var assets = [PersistedAsset]()

            let individualCoverWeight = 0.1 * (1 / Double(ImageSize.allCases.count))
            let individualPDFWeight = 0.1 * (1 / Double(supplementaryPDFs.count))
            let individualAudioTrackWeight = 0.8 * (1 / Double(audioTracks.count))

            assets += ImageSize.allCases.map { .init(itemID: itemID, fileType: .image(size: $0), progressWeight: individualCoverWeight) }
            assets += supplementaryPDFs.map { .init(itemID: itemID, fileType: .pdf(name: $0.fileName, ino: $0.ino), progressWeight: individualPDFWeight) }
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
                                         type: episode.type,
                                         index: episode.index)

                podcast?.episodes.append(model as! PersistedEpisode)
            default:
                fatalError("Unsupported item type: \(type(of: item))")
            }

            try modelContext.transaction {
                for chapter in chapters {
                    modelContext.insert(PersistedChapter(index: chapter.id, itemID: itemID, name: chapter.title, startOffset: chapter.startOffset, endOffset: chapter.endOffset))
                }

                for asset in assets {
                    modelContext.insert(asset)
                }

                modelContext.insert(model)
            }

            try modelContext.save()

            busy.remove(itemID)

            logger.info("Created download for \(itemID)")

            await MainActor.run {
                events.statusChanged.send((itemID, .downloading))
            }

            scheduleUpdateTask()

            await UIApplication.shared.endBackgroundTask(task)
        } catch {
            logger.error("Error creating download: \(error)")
            busy.remove(itemID)

            await UIApplication.shared.endBackgroundTask(task)

            throw error
        }
    }
    func remove(_ itemID: ItemIdentifier) async throws {
        logger.info("Removing download: \(itemID)")

        do {
            try await invalidateStatusCache()
        } catch {
            logger.error("Failed to remove download cache for \(itemID): \(error)")
        }

        guard itemID.type != .podcast else {
            guard let podcast = persistedPodcast(for: itemID) else {
                throw PersistenceError.missing
            }

            do {
                let episodes = try episodes(from: itemID)

                for episode in episodes {
                    do {
                        try await remove(episode.id)
                    } catch {
                        logger.error("Failed to remove episode \(episode.id) while removing podcast \(itemID): \(error)")
                    }
                }
            } catch {
                logger.error("Failed to fetch podcast episodes for \(itemID): \(error)")
            }

            do {
                let podcastAssets = try assets(for: itemID)

                do {
                    try await removeAssets(podcastAssets)
                } catch {
                    logger.error("Failed to remove podcast assets for \(itemID): \(error)")
                }
            } catch {
                logger.error("Failed to fetch podcast assets for \(itemID): \(error)")
            }

            for coverSize in ImageSize.allCases {
                coverURLCache.removeValue(forKey: "\(itemID)_\(coverSize)")
            }

            modelContext.delete(podcast)

            try modelContext.save()

            return
        }

        guard itemID.isPlayable else {
            throw PersistenceError.unsupportedItemType
        }

        guard !blocked.keys.contains(itemID) else {
            throw PersistenceError.blocked
        }

        guard !busy.contains(itemID) else {
            throw PersistenceError.busy
        }

        busy.insert(itemID)

        if let model: any PersistentModel = persistedAudiobook(for: itemID) ?? persistedEpisode(for: itemID) {
            modelContext.delete(model)
        } else {
            logger.error("Tried to delete non-existent model for \(itemID)")
        }

        do {
            try modelContext.delete(model: ShelfPlayerSchema.PersistedChapter.self, where: #Predicate { $0._itemID == itemID.description })
        } catch {
            logger.error("Failed to delete chapters for \(itemID): \(error)")
        }

        do {
            let assets = try assets(for: itemID)

            do {
                try await removeAssets(assets)
            } catch {
                logger.error("Failed to remove assets for \(itemID): \(error)")
            }
        } catch {
            logger.error("Failed to fetch assets for \(itemID): \(error)")
        }

        downloadStatusCache.removeValue(forKey: itemID)

        for coverSize in ImageSize.allCases {
            coverURLCache.removeValue(forKey: "\(itemID)_\(coverSize)")
        }

        do {
            try modelContext.save()
        } catch {
            logger.warning("Failed to save removal state for \(itemID, privacy: .public): \(error, privacy: .public)")
            busy.remove(itemID)
            throw error
        }

        busy.remove(itemID)

        await MainActor.run {
            events.statusChanged.send((itemID, .none))
        }

        do {
            try await removeEmptyPodcasts()
        } catch {
            logger.error("Failed to remove empty podcasts after removing \(itemID): \(error)")
        }
    }
    func removeAll() async throws {
        do {
            try modelContext.delete(model: PersistedAudiobook.self)
        } catch {
            logger.error("Failed to remove persisted audiobooks: \(error)")
        }

        do {
            for episode in try episodes() {
                do {
                    try await remove(episode.id)
                } catch {
                    logger.error("Failed to remove episode \(episode.id): \(error)")
                }
            }
        } catch {
            logger.error("Failed to enumerate persisted episodes for removal: \(error)")
        }

        do {
            try modelContext.delete(model: PersistedEpisode.self)
        } catch {
            logger.error("Failed to remove persisted episodes: \(error)")
        }

        do {
            try modelContext.delete(model: PersistedPodcast.self)
        } catch {
            logger.error("Failed to remove persisted podcasts: \(error)")
        }

        do {
            try modelContext.delete(model: PersistedAsset.self)
        } catch {
            logger.error("Failed to remove persisted assets: \(error)")
        }

        do {
            try modelContext.delete(model: PersistedChapter.self)
        } catch {
            logger.error("Failed to remove persisted chapters: \(error)")
        }

        do {
            let path = ShelfPlayerKit.downloadDirectoryURL
            try FileManager.default.removeItem(at: path)
        } catch {
            logger.error("Failed to remove download directory: \(error)")
        }

        await MainActor.run {
            events.statusChanged.send(nil)
        }
    }

    func invalidateStatusCache() async throws {
        downloadStatusCache.removeAll()
    }

    func addBlock(to itemID: ItemIdentifier) {
        if let existing = blocked[itemID] {
            blocked[itemID] = existing + 1
        } else {
            blocked[itemID] = 1
        }
    }
    func removeBlock(from itemID: ItemIdentifier) {
        guard let existing = blocked[itemID] else {
            logger.error("Tried to remove non existing block for item: \(itemID)")
            return
        }

        if existing == 1 {
            blocked[itemID] = nil
        } else {
            blocked[itemID] = existing - 1
        }
    }

    func invalidateActiveDownloads() {
        logger.info("Invalidating active downloads...")

        do {
            let assets = try modelContext.fetch(FetchDescriptor<PersistedAsset>(predicate: #Predicate { $0.downloadTaskID != nil }))

            for asset in assets {
                asset.downloadTaskID = nil
            }
        } catch {
            logger.error("Failed to fetch assets while invalidating active downloads: \(error)")
        }

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save context: \(error)")
        }

        Task {
            for task in await urlSession.tasks.2 {
                task.cancel()
            }
        }

        Task { @MainActor in
            self.events.statusChanged.send(nil)
        }
    }

    func search(query: String) async throws -> [ItemIdentifier] {
        let descriptor = FetchDescriptor<ShelfPlayerSchema.PersistedSearchIndexEntry>(predicate: #Predicate {
            $0.primaryName.localizedStandardContains(query)
            || $0.secondaryName?.localizedStandardContains(query) == true
            || $0.authorName.localizedStandardContains(query)
        })
        return try modelContext.fetch(descriptor).map(\.itemID)
    }
}

private final class URLSessionDelegate: NSObject, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destination = PersistenceManager.DownloadSubsystem.temporaryLocation(taskIdentifier: downloadTask.taskIdentifier)

        try? FileManager.default.removeItem(at: destination)

        do {
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

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        await PersistenceManager.shared.authorization.handleURLSessionChallenge(challenge)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task {
            await PersistenceManager.shared.download.reportProgress(taskID: downloadTask.taskIdentifier, bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
        Task {
            await PersistenceManager.shared.download.invalidateActiveDownloads()
        }
    }
}
