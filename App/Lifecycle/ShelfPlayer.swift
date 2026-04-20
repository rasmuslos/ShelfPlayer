//
//  ShelfPlayer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 04.03.25.
//

import Foundation
import OSLog
import Intents
import TipKit
import AppIntents
import BackgroundTasks
import ShelfPlayback

struct ShelfPlayer {
    static nonisolated let logger = Logger(subsystem: "io.rfk.ShelfPlayer", category: "Hooks")

    private static let settings = AppSettings.shared

    // MARK: Hooks

    static func launchHook() {
        do {
            try Tips.configure()
        } catch {
            logger.error("Failed to configure tips: \(error)")
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: SpotlightIndexer.BACKGROUND_TASK_IDENTIFIER, using: .main) { task in
            Task {
                await SpotlightIndexer.shared.handleBackgroundTask(task)
            }
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: PersistenceManager.ConvenienceDownloadSubsystem.BACKGROUND_TASK_IDENTIFIER, using: .main) {
            PersistenceManager.shared.convenienceDownload.handleBackgroundTask($0)
        }

        let intentAudioPlayer = EmbassyManager.shared.intentAudioPlayer
        AppDependencyManager.shared.add(dependency: PersistenceManager.shared)
        AppDependencyManager.shared.add(dependency: intentAudioPlayer)
    }

    static func initializeUIHook() {
        #if ENABLE_CENTRALIZED
        INPreferences.requestSiriAuthorization {
            logger.info("Got Siri authorization status: \($0.rawValue)")
        }
        #endif

        let lastBuild = settings.lastBuild

        // Fresh install
        if lastBuild == nil {
            settings.lastToSUpdate = ShelfPlayerKit.currentToSVersion
        }

        // Invalidate cache after an update
        let clientBuild = ShelfPlayerKit.clientBuild
        if let lastBuild, clientBuild < lastBuild {
            logger.info("ShelfPlayer has been updated. Invalidating cache...")

            Task {
                try await ShelfPlayer.invalidateCache()
            }

            Task { @MainActor in
                Satellite.shared.present(.whatsNew)
            }
        }

        settings.lastBuild = clientBuild

        // ToS
        let lastToSUpdate = settings.lastToSUpdate ?? -1
        if lastToSUpdate < ShelfPlayerKit.currentToSVersion {
            Task { @MainActor in
                Satellite.shared.warn(.termsOfServiceChanged)
            }
        }

        Task {
            await withTaskGroup {
                $0.addTask { await PersistenceManager.shared.download.invalidateActiveDownloads() }
                $0.addTask { await PersistenceManager.shared.download.scheduleUpdateTask() }

                $0.addTask { await PersistenceManager.shared.convenienceDownload.pruneFinishedDownloads() }

                $0.addTask { await EmbassyManager.shared.setupObservers() }
                $0.addTask { await EmbassyManager.shared.endSleepTimerActivity() }
            }
        }
    }

    @MainActor
    private static var didOnlineHookRun = false
    static func initOnlineUIHook() {
        Task { @MainActor in
            guard !didOnlineHookRun else {
                return
            }

            let connectionIDs = await PersistenceManager.shared.authorization.connectionIDs
            guard !connectionIDs.isEmpty else {
                return
            }

            didOnlineHookRun = true

            Embassy.unsetWidgetIsPlaying()
            AppShortcutProvider.updateAppShortcutParameters()

            await withTaskGroup {
                $0.addTask { await ContextProvider.updateUserContext() }
                $0.addTask { await PlayMediaIntentHandler.donateListenNowIntents() }

                $0.addTask { await SpotlightIndexer.shared.scheduleBackgroundTask() }
                $0.addTask { await PersistenceManager.shared.convenienceDownload.scheduleBackgroundTask(shouldWait: false) }
            }
        }
    }

    // MARK: Actions

    @concurrent
    static func generateLogArchive() async throws -> URL {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let predicate = NSPredicate(format: "subsystem BEGINSWITH %@", "io.rfk.")

        let all = try store.getEntries()
        let filtered = try store.getEntries(matching: predicate)

        let name = Date.now.formatted(.iso8601)
        let baseURL = FileManager.default.temporaryDirectory.appending(path: name)

        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

        try await writeLogEntitiesToFile(all, at: baseURL.appending(path: "ShelfPlayerAll.log"))
        try await writeLogEntitiesToFile(filtered, at: baseURL.appending(path: "ShelfPlayerFiltered.log"))
        try await writeGeneralStateToFile(at: baseURL.appending(path: "ShelfPlayerState.log"))

        var error: NSError?
        var moveError: Error?

        let coordinator = NSFileCoordinator()
        let targetURL = FileManager.default.temporaryDirectory.appending(path: "\(name).log.zip")

        coordinator.coordinate(readingItemAt: baseURL, options: .forUploading, error: &error) {
            do {
                try FileManager.default.moveItem(at: $0, to: targetURL)
            } catch {
                logger.warning("Failed to move coordinated log archive to \(targetURL.lastPathComponent, privacy: .public): \(error, privacy: .public)")
                moveError = error
            }
        }

        if let error {
            logger.error("Failed to create zip log archive: \(error)")
            throw error
        }

        if let moveError {
            throw moveError
        }

        return targetURL
    }

    // MARK: Diagnostics

    @concurrent
    static func cacheDiagnostics() async -> CacheDiagnostics {
        async let downloadCount = PersistenceManager.shared.download.totalCount
        async let progressCount = PersistenceManager.shared.progress.totalCount

        let imageCachePath = await ImageLoader.shared.cachePath
        let itemCachePath = await ResolveCache.shared.cachePath

        let imageCount = recursiveFileCount(in: imageCachePath)
        let itemCount = recursiveFileCount(in: itemCachePath)

        return .init(downloadCount: await downloadCount,
                     imageCount: imageCount,
                     itemCount: itemCount,
                     progressCount: await progressCount,
                     cacheDirectorySize: try? ShelfPlayerKit.cacheDirectoryURL.directoryTotalAllocatedSize(),
                     downloadDirectorySize: try? ShelfPlayerKit.downloadDirectoryURL.directoryTotalAllocatedSize())
    }

    // MARK: Cache invalidation

    static func invalidateShortTermCache() async {
        await ABSClient.flushClientCache()

        logger.info("Invalidating short term cache...")

        PersistenceManager.shared.download.events.statusChanged.send(nil)
        PersistenceManager.shared.progress.events.invalidateEntities.send(nil)
    }

    static func refreshItem(itemID: ItemIdentifier) async throws {
        await ABSClient.flushClientCache()

        await invalidateShortTermCache()

        await ImageLoader.shared.purge(itemID: itemID)
        await ResolveCache.shared.invalidate(itemID: itemID)

        AppEventSource.shared.reloadImages.send(itemID)
        PersistenceManager.shared.download.events.statusChanged.send(nil)

        try await PersistenceManager.shared.refreshItem(itemID: itemID)
    }

    static func invalidateCache() async throws {
        await PersistenceManager.shared.convenienceDownload.resetRunsInExtendedBackgroundTask()

        do {
            try await SpotlightIndexer.shared.reset()
        } catch {
            logger.warning("Failed to reset SpotlightIndexer: \(error)")
        }

        await ABSClient.flushClientCache()
        await ResolveCache.shared.flush()

        await ImageLoader.shared.purge()
        AppEventSource.shared.reloadImages.send(nil)

        try await PersistenceManager.shared.invalidateCache()
    }

    struct CacheDiagnostics: Sendable {
        let downloadCount: Int
        let imageCount: Int
        let itemCount: Int
        let progressCount: Int

        let cacheDirectorySize: Int?
        let downloadDirectorySize: Int?
    }
}

private extension ShelfPlayer {
    @concurrent
    static func writeLogEntitiesToFile(_ entities: AnySequence<OSLogEntry>, at url: URL) async throws {
        try entities.map {
            "\($0.date.formatted(.iso8601)): \($0.composedMessage)"
        }.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    @concurrent
    static func writeGeneralStateToFile(at url: URL) async throws {
        let now = Date.now

        let cacheDiagnostics = await cacheDiagnostics()

        async let friendlyConnections = PersistenceManager.shared.authorization.friendlyConnections

        async let currentItemID = AudioPlayer.shared.currentItemID
        async let isPlaying = AudioPlayer.shared.isPlaying
        async let isBuffering = AudioPlayer.shared.isBusy
        async let queue = AudioPlayer.shared.queue
        async let upNextQueue = AudioPlayer.shared.upNextQueue
        async let playbackRate = AudioPlayer.shared.playbackRate
        async let sleepTimer = AudioPlayer.shared.sleepTimer
        async let route = AudioPlayer.shared.route

        let osVersion: String

        #if canImport(UIKit)
        osVersion = await ShelfPlayerKit.osVersion
        #else
        osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #endif

        let resolvedConnections = await friendlyConnections

        let resolvedCurrentItemID = await currentItemID
        let resolvedIsPlaying = await isPlaying
        let resolvedIsBuffering = await isBuffering
        let resolvedQueue = await queue
        let resolvedUpNextQueue = await upNextQueue
        let resolvedPlaybackRate = await playbackRate
        let resolvedSleepTimer = await sleepTimer
        let resolvedRoute = await route

        var lines = [String]()

        lines.append("# ShelfPlayer State Snapshot")
        lines.append("generatedAt=\(now.formatted(.iso8601))")
        lines.append("bundleIdentifier=\(Bundle.main.bundleIdentifier ?? "unknown")")
        lines.append("offlineModeEnabled=\(await OfflineMode.shared.isEnabled)")
        lines.append("offlineModeLoading=\(await OfflineMode.shared.isLoading)")
        lines.append("")

        lines.append("[device]")
        lines.append("model=\(ShelfPlayerKit.model)")
        lines.append("osVersion=\(osVersion)")
        lines.append("clientVersion=\(ShelfPlayerKit.clientVersion)")
        lines.append("clientBuild=\(ShelfPlayerKit.clientBuild)")
        lines.append("enableCentralized=\(ShelfPlayerKit.enableCentralized)")
        lines.append("groupContainer=\(ShelfPlayerKit.groupContainer)")
        lines.append("")

        lines.append("[cache]")
        lines.append("downloads=\(cacheDiagnostics.downloadCount)")
        lines.append("images=\(cacheDiagnostics.imageCount)")
        lines.append("items=\(cacheDiagnostics.itemCount)")
        lines.append("progress=\(cacheDiagnostics.progressCount)")

        if let cacheDirectorySize = cacheDiagnostics.cacheDirectorySize {
            lines.append("cacheSizeBytes=\(cacheDirectorySize)")
        } else {
            lines.append("cacheSizeBytes=<none>")
        }

        if let downloadDirectorySize = cacheDiagnostics.downloadDirectorySize {
            lines.append("downloadSizeBytes=\(downloadDirectorySize)")
        } else {
            lines.append("downloadSizeBytes=<none>")
        }

        lines.append("")
        lines.append("[connections]")
        lines.append("count=\(resolvedConnections.count)")

        if resolvedConnections.isEmpty {
            lines.append("entries=<none>")
        } else {
            for connection in resolvedConnections {
                lines.append("\(connection.id)=\(connection.name)")
            }
        }

        #if DEBUG
        lines.append("activeWebSocketConnections=\(await PersistenceManager.shared.webSocket.connected)")
        #endif

        lines.append("")
        lines.append("[player]")
        lines.append("currentItemID=\(resolvedCurrentItemID?.description ?? "<none>")")
        lines.append("isPlaying=\(resolvedIsPlaying)")
        lines.append("isBuffering=\(resolvedIsBuffering)")
        lines.append("queueCount=\(resolvedQueue.count)")
        lines.append("upNextQueueCount=\(resolvedUpNextQueue.count)")
        lines.append("playbackRate=\(resolvedPlaybackRate)")
        lines.append("sleepTimer=\(String(describing: resolvedSleepTimer))")
        lines.append("routeIcon=\(resolvedRoute?.icon ?? "<none>")")

        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    nonisolated static func recursiveFileCount(in directoryURL: URL) -> Int {
        let keys: Set<URLResourceKey> = [.isRegularFileKey]

        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants],
            errorHandler: nil
        ) else {
            return 0
        }

        var count = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: keys), values.isRegularFile == true else {
                continue
            }

            count += 1
        }

        return count
    }
}
