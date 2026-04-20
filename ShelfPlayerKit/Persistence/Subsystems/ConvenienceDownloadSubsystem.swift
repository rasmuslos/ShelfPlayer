//
//  ConvenienceDownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 03.05.25.
//

import Combine
import Foundation
import OSLog
@preconcurrency import BackgroundTasks

private let LISTEN_NOW_CONFIGURATION_ID = "listen-now"

extension PersistenceManager {
    public final actor ConvenienceDownloadSubsystem {
        public final class EventSource: @unchecked Sendable {
            public let configurationsChanged = PassthroughSubject<Void, Never>()
            public let iteration = PassthroughSubject<Void, Never>()

            init() {}
        }

        public static let BACKGROUND_TASK_IDENTIFIER = "io.rfk.shelfPlayer.convenienceDownload"

        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ConvenienceDownloadSubsystem")

        var task: Task<Void, Never>?
        var pendingConfigurationIDs = Set<String>()
        private var observerSubscriptions = Set<AnyCancellable>()
        nonisolated(unsafe) private var backgroundTaskIterationSubscription: AnyCancellable?
        public nonisolated let events = EventSource()

        nonisolated(unsafe) var shouldComeToEnd = false

        // In-memory stores replacing key-value subsystem
        var retrievals = [String: GroupingRetrieval]()
        var downloadedItemIDs = [String: Set<ItemIdentifier>]()
        var associatedConfigurationIDs = [ItemIdentifier: Set<String>]()
        var runExtendedBackgroundTask = false

        init() {
            Task {
                await setupObserverSubscriptions()
            }

            Task {
                // Monitor enableListenNowDownloads changes
                if AppSettings.shared.enableListenNowDownloads {
                    await scheduleDownload(configurationID: LISTEN_NOW_CONFIGURATION_ID)
                }
            }
        }

        private func setupObserverSubscriptions() {
            PersistenceManager.shared.listenNow.events.itemsChanged
                .sink { [weak self] _ in
                    guard AppSettings.shared.enableListenNowDownloads else {
                        return
                    }
                    guard let self else {
                        return
                    }

                    Task {
                        await self.scheduleDownload(configurationID: LISTEN_NOW_CONFIGURATION_ID)
                    }
                }
                .store(in: &observerSubscriptions)

            PersistenceManager.shared.progress.events.entityUpdated
                .sink { [weak self] connectionID, primaryID, groupingID, entity in
                    guard let self else {
                        return
                    }

                    Task {
                        guard entity?.isFinished == true,
                              let item = try? await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID),
                              let configurationIDs = await self.associatedConfigurationIDs[item.id] else {
                            return
                        }

                        for configurationID in configurationIDs {
                            await self.scheduleDownload(configurationID: configurationID)
                        }
                    }
                }
                .store(in: &observerSubscriptions)
        }

        // MARK: Removal

        nonisolated func remove(itemID: ItemIdentifier, configurationID: String?) async {
            await removeOrphans(configurationID: buildGroupingConfigurationID(itemID))

            let associatedConfigs = await self.associatedConfigurationIDs[itemID]

            if let associatedConfigs, !associatedConfigs.isEmpty {
                if (associatedConfigs.count == 1 && associatedConfigs.first == configurationID) || configurationID == nil {
                    try? await PersistenceManager.shared.download.remove(itemID)
                    await self.setAssociatedConfigurationIDs(nil, for: itemID)
                } else if let configurationID {
                    var updated = associatedConfigs
                    updated.remove(configurationID)
                    await self.setAssociatedConfigurationIDs(updated, for: itemID)
                }
            }
        }
        nonisolated func removeOrphans(configurationID: String) async {
            if let downloaded = await self.getDownloadedItemIDs(for: configurationID) {
                for itemID in downloaded {
                    await remove(itemID: itemID, configurationID: configurationID)
                }

                await self.setDownloadedItemIDs(nil, for: configurationID)
            }
        }
    }
}

private extension PersistenceManager.ConvenienceDownloadSubsystem {
    func scheduleDownload(configurationID: String) {
        pendingConfigurationIDs.insert(configurationID)
        scheduleTask()
    }

    // MARK: Task

    func scheduleTask() {
        guard AppSettings.shared.enableConvenienceDownloads else {
            logger.warning("Not running convenience download task because feature is disabled")
            return
        }

        guard task == nil else {
            logger.warning("Not running convenience download task because one is already running")
            return
        }

        guard !pendingConfigurationIDs.isEmpty else {
            logger.info("Finished running convenience download task.")
            AppSettings.shared.lastConvenienceDownloadRun = .now

            return
        }

        let configurationID = pendingConfigurationIDs.removeFirst()

        task = .detached {
            await self.download(configurationID: configurationID)
            await MainActor.run {
                self.events.iteration.send()
            }

            await self.unscheduleTask()

            if !self.shouldComeToEnd {
                await self.scheduleTask()
            }
        }
    }
    func unscheduleTask() {
        task = nil
    }

    // MARK: Download

    nonisolated func download(configurationID: String) async {
        guard let configuration = try? await resolveConfiguration(id: configurationID) else {
            logger.error("Failed to resolve configuration: \(configurationID)")
            return
        }

        let shouldPruneOrphans: Bool

        switch configuration {
        case .listenNow:
            shouldPruneOrphans = false
        case .grouping:
            shouldPruneOrphans = true
        }

        logger.info("Begin convenience download of configuration: \(configurationID)")

        do {
            let items = try await configuration.items

            let itemIDs = Set(items.map(\.id))
            var downloaded = await self.getDownloadedItemIDs(for: configurationID) ?? []

            for itemID in downloaded {
                if await PersistenceManager.shared.download.status(of: itemID) == .none {
                    downloaded.remove(itemID)
                }
            }

            let missingDownloads = itemIDs.subtracting(downloaded)
            var queuedDownloads = Set<ItemIdentifier>()

            if missingDownloads.isEmpty {
                logger.info("Nothing to download for configuration: \(configurationID)")
            } else {
                for itemID in missingDownloads {
                    if await PersistenceManager.shared.download.status(of: itemID) == .none {
                        do {
                            try await PersistenceManager.shared.download.download(itemID)
                        } catch PersistenceError.existing, PersistenceError.busy {
                            logger.info("Skipping queue for convenience item because it already exists or is busy: \(itemID)")
                        } catch {
                            logger.error("Failed to download item: \(error)")
                            continue
                        }
                    }

                    var associatedConfigs = await self.getAssociatedConfigurationIDs(for: itemID) ?? .init()
                    associatedConfigs.insert(configurationID)
                    await self.setAssociatedConfigurationIDs(associatedConfigs, for: itemID)

                    queuedDownloads.insert(itemID)
                }
            }

            let updatedDownloadedIDs: Set<ItemIdentifier>
            let orphanedDownloads: Set<ItemIdentifier>

            if shouldPruneOrphans {
                updatedDownloadedIDs = downloaded.intersection(itemIDs).union(queuedDownloads)
                orphanedDownloads = downloaded.subtracting(updatedDownloadedIDs)
            } else {
                updatedDownloadedIDs = downloaded.union(queuedDownloads)
                orphanedDownloads = []
            }

            await self.setDownloadedItemIDs(updatedDownloadedIDs, for: configurationID)

            if !orphanedDownloads.isEmpty {
                for itemID in orphanedDownloads {
                    guard await OfflineMode.shared.isAvailable(itemID.connectionID) else {
                        logger.info("Skipping orphaned download because the associated connection is not available: \(itemID)")
                        continue
                    }

                    await remove(itemID: itemID, configurationID: configurationID)
                }
            }

            logger.info("Finished evaluating downloads for \(configurationID). Downloaded: \(downloaded.count), Queued: \(queuedDownloads.count), Orphaned: \(orphanedDownloads.count), Updated: \(updatedDownloadedIDs.count)")
        } catch {
            logger.error("Failed to download configuration: \(error)")
        }
    }
    nonisolated func resolveConfiguration(id: String) async throws -> ConvenienceDownloadConfiguration {
        if id == LISTEN_NOW_CONFIGURATION_ID {
            return .listenNow
        }

        if let itemID = resolveItemID(from: id), let retrieval = await self.getRetrieval(for: id) {
            return .grouping(itemID, retrieval)
        }

        throw ConvenienceDownloadError.notFound
    }
}

public extension PersistenceManager.ConvenienceDownloadSubsystem {
    var currentProgress: Percentage {
        get async {
            var total = retrievals.count

            if AppSettings.shared.enableListenNowDownloads {
                total += 1
            }

            var pending = pendingConfigurationIDs.count

            if task != nil {
                pending += 1
            }

            return Double(total - pending) / Double(total)
        }
    }

    nonisolated func resolveItemID(from configurationID: String) -> ItemIdentifier? {
        guard configurationID.starts(with: "grouping-") else {
            return nil
        }

        let itemIDDescription = configurationID[configurationID.index(after: configurationID.firstIndex(of: "-")!)..<configurationID.endIndex]
        return ItemIdentifier(String(itemIDDescription))
    }
    nonisolated func isManaged(itemID: ItemIdentifier) async -> Bool {
        await self.getAssociatedConfigurationIDs(for: itemID)?.isEmpty == false
    }

    nonisolated func removeConfigurations(associatedWith itemID: ItemIdentifier) async {
        guard let configurationIDs = await self.getAssociatedConfigurationIDs(for: itemID) else {
            return
        }

        for configurationID in configurationIDs {
            do {
                try await resolveConfiguration(id: configurationID).disable()
            } catch {
                logger.error("Failed to disable configuration \(configurationID): \(error)")
            }
        }
    }

    // MARK: Retrieval

    nonisolated func retrieval(for itemID: ItemIdentifier) async -> GroupingRetrieval? {
        await self.getRetrieval(for: buildGroupingConfigurationID(itemID))
    }
    nonisolated func setRetrieval(for itemID: ItemIdentifier, retrieval: GroupingRetrieval?) async throws {
        if let retrieval {
            let configurationID = buildGroupingConfigurationID(itemID)

            await self.setRetrieval(retrieval, for: configurationID)
            await scheduleDownload(configurationID: configurationID)
        } else {
            await remove(itemID: itemID, configurationID: buildGroupingConfigurationID(itemID))
        }

        await MainActor.run {
            events.configurationsChanged.send()
        }
    }

    nonisolated var activeConfigurations: [ConvenienceDownloadConfiguration] {
        get async {
            guard AppSettings.shared.enableConvenienceDownloads else {
                return []
            }

            var configurations = [ConvenienceDownloadConfiguration]()

            if AppSettings.shared.enableListenNowDownloads {
                configurations.append(.listenNow)
            }

            let allRetrievals = await self.allRetrievals

            configurations += allRetrievals.compactMap { (key, retrieval) -> ConvenienceDownloadConfiguration? in
                guard let itemID = resolveItemID(from: key) else {
                    return nil
                }

                return .grouping(itemID, retrieval)
            }

            return configurations
        }
    }
    nonisolated var totalDownloadCount: Int {
        get async {
            await self.associatedConfigurationIDs.count
        }
    }

    // MARK: Schedule

    func scheduleUpdate(itemID: ItemIdentifier) async {
        guard retrievals[buildGroupingConfigurationID(itemID)] != nil else {
            return
        }

        shouldComeToEnd = false
        scheduleDownload(configurationID: buildGroupingConfigurationID(itemID))
    }
    func scheduleAll() async {
        shouldComeToEnd = false

        let configurations = await activeConfigurations

        for configuration in configurations {
            scheduleDownload(configurationID: configuration.id)
        }

        logger.info("Queued \(configurations.count) configurations for download")
    }

    // MARK: Events

    nonisolated func pruneFinishedDownloads() async {
        let itemIDs: Set<ItemIdentifier>

        do {
            let audiobookIDs = try await PersistenceManager.shared.download.audiobooks().map(\.id)
            let episodeIDs = try await PersistenceManager.shared.download.episodes().map(\.id)
            itemIDs = Set(audiobookIDs + episodeIDs)
        } catch {
            logger.error("Failed to fetch downloaded items while pruning finished downloads: \(error)")
            return
        }

        guard !itemIDs.isEmpty else {
            return
        }

        var pendingConfigIDs = Set<String>()
        var pruned = 0

        for itemID in itemIDs {
            guard await PersistenceManager.shared.progress[itemID].isFinished else {
                continue
            }

            let associatedConfigs = await self.getAssociatedConfigurationIDs(for: itemID) ?? []
            pendingConfigIDs.formUnion(associatedConfigs)

            guard AppSettings.shared.removeFinishedDownloads else {
                continue
            }

            do {
                try await PersistenceManager.shared.download.remove(itemID)

                if !associatedConfigs.isEmpty {
                    await self.setAssociatedConfigurationIDs(nil, for: itemID)
                }

                pruned += 1
            } catch {
                logger.error("Failed to remove downloaded item \(itemID) while pruning finished downloads: \(error)")
            }
        }

        for configurationID in pendingConfigIDs {
            await scheduleDownload(configurationID: configurationID)
        }

        logger.info("Pruned \(pruned) finished downloads and scheduled \(pendingConfigIDs.count) convenience configuration updates")
    }

    // MARK: Background-Task

    nonisolated var runsInExtendedBackgroundTask: Bool {
        get async {
            await self.runExtendedBackgroundTask
        }
    }
    func resetRunsInExtendedBackgroundTask() async {
        runExtendedBackgroundTask = false
    }

    nonisolated func scheduleBackgroundTask(shouldWait: Bool) async {
        guard await BGTaskScheduler.shared.pendingTaskRequests().first(where: { $0.identifier == Self.BACKGROUND_TASK_IDENTIFIER }) == nil else {
            logger.warning("Requested background task even though it is already scheduled")
            return
        }

        let request: BGTaskRequest

        if await runsInExtendedBackgroundTask {
            let processingRequest = BGProcessingTaskRequest(identifier: Self.BACKGROUND_TASK_IDENTIFIER)

            processingRequest.earliestBeginDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
            processingRequest.requiresNetworkConnectivity = true

            request = processingRequest

            if Int.random(in: 0..<100) == 0 {
                await self.resetRunsInExtendedBackgroundTask()
            }
        } else {
            request = BGAppRefreshTaskRequest(identifier: Self.BACKGROUND_TASK_IDENTIFIER)

            if shouldWait {
                request.earliestBeginDate = .now.advanced(by: 60 * 60 * 3)
            }
        }

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

            Task {
                await self.setRunExtendedBackgroundTask(true)
            }
        }

        backgroundTaskIterationSubscription = events.iteration
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                Task {
                    let currentProgress = await self.currentProgress

                    guard currentProgress >= 1 else {
                        return
                    }

                    await self.scheduleBackgroundTask(shouldWait: true)
                    self.backgroundTaskIterationSubscription = nil
                    task.setTaskCompleted(success: true)
                }
            }

        Task {
            await self.scheduleAll()
        }
    }

    func purge(connectionID: ItemIdentifier.ConnectionID) async {
        pendingConfigurationIDs.removeAll()
        await MainActor.run {
            events.configurationsChanged.send()
        }
    }
    func purge() async {
        shouldComeToEnd = true
        task?.cancel()

        task = nil
        pendingConfigurationIDs.removeAll()

        retrievals.removeAll()
        downloadedItemIDs.removeAll()
        associatedConfigurationIDs.removeAll()
        runExtendedBackgroundTask = false

        shouldComeToEnd = false

        await MainActor.run {
            events.configurationsChanged.send()
        }
    }

    // MARK: Types

    enum ConvenienceDownloadConfiguration: Codable, Sendable, Identifiable {
        case listenNow
        case grouping(ItemIdentifier, GroupingRetrieval)

        public var id: String {
            switch self {
            case .listenNow:
                LISTEN_NOW_CONFIGURATION_ID
            case .grouping(let itemID, _):
                buildGroupingConfigurationID(itemID)
            }
        }

        func disable() async throws {
            switch self {
            case .listenNow:
                AppSettings.shared.enableListenNowDownloads = false
            case .grouping(let itemID, _):
                try await PersistenceManager.shared.convenienceDownload.setRetrieval(for: itemID, retrieval: nil)
            }
        }

        var items: [PlayableItem] {
            get async throws {
                switch self {
                case .grouping(let itemID, let retrieval):
                    let strategy: ResolvedUpNextStrategy

                    switch itemID.type {
                    case .series:
                        strategy = .series(itemID)
                    case .podcast:
                        strategy = .podcast(itemID)
                    case .collection, .playlist:
                        strategy = .collection(itemID)
                    default:
                        throw ConvenienceDownloadError.invalidItemType
                    }

                    let items = try await strategy.resolve(cutoff: nil)
                    let result: [PlayableItem]

                    switch retrieval {
                    case .all:
                        result = items
                    case .amount(let count):
                        result = Array(items[0..<min(count, items.count)])
                    case .cutoff(let hours):
                        result = items.filter {
                            if let episode = $0 as? Episode, let releaseDate = episode.releaseDate {
                                releaseDate.distance(to: Date()) < TimeInterval(60 * 60 * hours)
                            } else {
                                false
                            }
                        }
                    }

                    return result
                case .listenNow:
                    guard await !OfflineMode.shared.isEnabled else {
                        throw APIClientError.offline
                    }

                    return try await PersistenceManager.shared.listenNow.current
                }
            }
        }
    }
    enum GroupingRetrieval: Codable, Sendable {
        case all
        case amount(Int)
        case cutoff(Int)
    }

    private enum ConvenienceDownloadError: Error {
        case notFound
        case invalidItemType
    }
}

// MARK: Migration

public extension PersistenceManager.ConvenienceDownloadSubsystem {
    func restoreMigratedState(
        retrievals: [String: GroupingRetrieval],
        downloadedItemIDs: [String: Set<ItemIdentifier>],
        associatedConfigurationIDs: [ItemIdentifier: Set<String>]
    ) {
        self.retrievals.merge(retrievals) { _, new in new }
        self.downloadedItemIDs.merge(downloadedItemIDs) { _, new in new }
        self.associatedConfigurationIDs.merge(associatedConfigurationIDs) { _, new in new }
    }
}

// MARK: In-memory store accessors

extension PersistenceManager.ConvenienceDownloadSubsystem {
    func getRetrieval(for configurationID: String) -> GroupingRetrieval? {
        retrievals[configurationID]
    }
    func setRetrieval(_ retrieval: GroupingRetrieval?, for configurationID: String) {
        retrievals[configurationID] = retrieval
    }
    var allRetrievals: [String: GroupingRetrieval] {
        retrievals
    }

    func getDownloadedItemIDs(for configurationID: String) -> Set<ItemIdentifier>? {
        downloadedItemIDs[configurationID]
    }
    func setDownloadedItemIDs(_ ids: Set<ItemIdentifier>?, for configurationID: String) {
        downloadedItemIDs[configurationID] = ids
    }

    func getAssociatedConfigurationIDs(for itemID: ItemIdentifier) -> Set<String>? {
        associatedConfigurationIDs[itemID]
    }
    func setAssociatedConfigurationIDs(_ ids: Set<String>?, for itemID: ItemIdentifier) {
        associatedConfigurationIDs[itemID] = ids
    }

    func setRunExtendedBackgroundTask(_ value: Bool) {
        runExtendedBackgroundTask = value
    }
}

private func buildGroupingConfigurationID(_ itemID: ItemIdentifier) -> String {
    "grouping-\(itemID)"
}
