//
//  ConvenienceDownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 03.05.25.
//

import Foundation
import OSLog
@preconcurrency import BackgroundTasks
import RFNotifications

private let LISTEN_NOW_CONFIGURATION_ID = "listen-now"

private let RETRIEVALS_KEY_VALUE_CLUSTER = "convenienceDownloadRetrievals"
private let DOWNLOADED_KEY_VALUE_CLUSTER = "downloadedItemIDs"
private let ASSOCIATED_KEY_VALUE_CLUSTER = "associatedConfigurationIDs"

extension PersistenceManager {
    public final actor ConvenienceDownloadSubsystem {
        public static let BACKGROUND_TASK_IDENTIFIER = "io.rfk.shelfPlayer.convenienceDownload"
        
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ConvenienceDownloadSubsystem")
        
        var task: Task<Void, Never>?
        var pendingConfigurationIDs = Set<String>()
        
        nonisolated(unsafe) var shouldComeToEnd = false
        
        init() {
            RFNotification[.listenNowItemsChanged].subscribe { [weak self] in
                guard Defaults[.enableListenNowDownloads] else {
                    return
                }
                
                Task {
                    await self?.scheduleDownload(configurationID: LISTEN_NOW_CONFIGURATION_ID)
                }
            }
            
            Task {
                for await enabled in Defaults.updates(.enableListenNowDownloads, initial: false) {
                    if enabled {
                        await scheduleDownload(configurationID: LISTEN_NOW_CONFIGURATION_ID)
                    } else {
                        await removeOrphans(configurationID: LISTEN_NOW_CONFIGURATION_ID)
                    }
                }
            }
            Task {
                for await _ in Defaults.updates([.enableConvenienceDownloads, .enableListenNowDownloads], initial: false) {
                    await RFNotification[.convenienceDownloadConfigurationsChanged].send()
                }
            }
            
            RFNotification[.progressEntityUpdated].subscribe { [weak self] connectionID, primaryID, groupingID, entity in
                Task {
                    guard entity?.isFinished == true,
                          let item = try? await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID),
                          let configurationIDs = await PersistenceManager.shared.keyValue[.associatedConfigurationIDs(itemID: item.id)] else {
                        return
                    }
                                        
                    for configurationID in configurationIDs {
                        await self?.scheduleDownload(configurationID: configurationID)
                    }
                }
            }
        }
        
        // MARK: Removal
        
        nonisolated func remove(itemID: ItemIdentifier, configurationID: String?) async {
            do {
                try await PersistenceManager.shared.keyValue.set(.convenienceDownloadRetrieval(itemID: itemID), nil)
            } catch {
                logger.error("Failed to remove convenience download configuration for item \(itemID): \(error)")
            }
            
            await removeOrphans(configurationID: buildGroupingConfigurationID(itemID))
            
            if var associatedConfigurationIDs = await PersistenceManager.shared.keyValue[.associatedConfigurationIDs(itemID: itemID)] {
                do {
                    if (associatedConfigurationIDs.count == 1 && associatedConfigurationIDs.first == configurationID) || configurationID == nil {
                        try await PersistenceManager.shared.download.remove(itemID)
                        try await PersistenceManager.shared.keyValue.set(.associatedConfigurationIDs(itemID: itemID), nil)
                    } else if let configurationID {
                        associatedConfigurationIDs.remove(configurationID)
                        try await PersistenceManager.shared.keyValue.set(.associatedConfigurationIDs(itemID: itemID), associatedConfigurationIDs)
                    }
                } catch {
                    logger.error("Failed to remove associated configuration IDs for item \(itemID): \(error)")
                }
            }
        }
        nonisolated func removeOrphans(configurationID: String) async {
            if let downloaded = await PersistenceManager.shared.keyValue[.downloadedItemIDs(configurationID: configurationID)] {
                for itemID in downloaded {
                    await remove(itemID: itemID, configurationID: configurationID)
                }
                
                do {
                    try await PersistenceManager.shared.keyValue.set(.downloadedItemIDs(configurationID: configurationID), nil)
                } catch {
                    logger.error("Failed to remove orphaned downloads for configuration \(configurationID): \(error)")
                }
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
        guard Defaults[.enableConvenienceDownloads] else {
            logger.warning("Not running convenience download task because feature is disabled")
            return
        }
        
        guard task == nil else {
            logger.warning("Not running convenience download task because one is already running")
            return
        }
        
        guard !pendingConfigurationIDs.isEmpty else {
            logger.info("Finished running convenience download task.")
            Defaults[.lastConvenienceDownloadRun] = .now
            
            return
        }
        
        let configurationID = pendingConfigurationIDs.removeFirst()
        
        task = .detached {
            await self.download(configurationID: configurationID)
            await RFNotification[.convenienceDownloadIteration].send()
            
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
        
        logger.info("Begin convenience download of configuration: \(configurationID)")
        
        do {
            let items = try await configuration.items
            
            let itemIDs = Set(items.map(\.id))
            var downloaded = await PersistenceManager.shared.keyValue[.downloadedItemIDs(configurationID: configurationID)] ?? []
            
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
                        } catch {
                            logger.error("Failed to download item: \(error)")
                            continue
                        }
                    }
                    
                    var associatedConfigurations = await PersistenceManager.shared.keyValue[.associatedConfigurationIDs(itemID: itemID)] ?? .init()
                    associatedConfigurations.insert(configurationID)
                    
                    do {
                        try await PersistenceManager.shared.keyValue.set(.associatedConfigurationIDs(itemID: itemID), associatedConfigurations)
                    } catch {
                        logger.error("Failed to store associated configurations for \(itemID): \(error)")
                        continue
                    }
                    
                    queuedDownloads.insert(itemID)
                }
            }
            
            let updatedDownloadedIDs = downloaded.intersection(itemIDs).union(queuedDownloads)
            let orphanedDownloads = downloaded.subtracting(updatedDownloadedIDs)
            
            try await PersistenceManager.shared.keyValue.set(.downloadedItemIDs(configurationID: configurationID), updatedDownloadedIDs)
            
            if !orphanedDownloads.isEmpty {
                for itemID in orphanedDownloads {
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
        
        if let itemID = resolveItemID(from: id), let retrieval = await PersistenceManager.shared.keyValue[.convenienceDownloadRetrieval(configurationID: id)] {
            return .grouping(itemID, retrieval)
        }
        
        throw ConvenienceDownloadError.notFound
    }
}

public extension PersistenceManager.ConvenienceDownloadSubsystem {
    var currentProgress: Percentage {
        get async {
            var total = await PersistenceManager.shared.keyValue.entityCount(cluster: RETRIEVALS_KEY_VALUE_CLUSTER)
            
            if Defaults[.enableListenNowDownloads] {
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
        await PersistenceManager.shared.keyValue[.associatedConfigurationIDs(itemID: itemID)]?.isEmpty == false
    }
    
    nonisolated func removeConfigurations(associatedWith itemID: ItemIdentifier) async {
        guard let configurationIDs = await PersistenceManager.shared.keyValue[.associatedConfigurationIDs(itemID: itemID)] else {
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
        await PersistenceManager.shared.keyValue[.convenienceDownloadRetrieval(itemID: itemID)]
    }
    nonisolated func setRetrieval(for itemID: ItemIdentifier, retrieval: GroupingRetrieval?) async throws {
        if let retrieval {
            let configurationID = buildGroupingConfigurationID(itemID)
            
            try await PersistenceManager.shared.keyValue.set(.convenienceDownloadRetrieval(configurationID: configurationID), retrieval)
            await scheduleDownload(configurationID: configurationID)
        } else {
            await remove(itemID: itemID, configurationID: buildGroupingConfigurationID(itemID))
        }
        
        await RFNotification[.convenienceDownloadConfigurationsChanged].send()
    }
    
    nonisolated var activeConfigurations: [ConvenienceDownloadConfiguration] {
        get async {
            guard Defaults[.enableConvenienceDownloads] else {
                return []
            }
            
            var configurations = [ConvenienceDownloadConfiguration]()
            
            if Defaults[.enableListenNowDownloads] {
                configurations.append(.listenNow)
            }
            
            let retrievals = await PersistenceManager.shared.keyValue.entities(cluster: RETRIEVALS_KEY_VALUE_CLUSTER, type: GroupingRetrieval.self)
            
            configurations += retrievals.compactMap { (key, retrieval) -> ConvenienceDownloadConfiguration? in
                let configurationID = String(key[key.index(after: key.firstIndex(of: "-")!)..<key.endIndex])
                
                guard let itemID = resolveItemID(from: configurationID) else {
                    return nil
                }
                
                return .grouping(itemID, retrieval)
            }
            
            return configurations
        }
    }
    nonisolated var totalDownloadCount: Int {
        get async {
            await PersistenceManager.shared.keyValue.entityCount(cluster: ASSOCIATED_KEY_VALUE_CLUSTER)
        }
    }
    
    // MARK: Schedule
    
    func scheduleUpdate(itemID: ItemIdentifier) async {
        guard await PersistenceManager.shared.keyValue[.convenienceDownloadRetrieval(itemID: itemID)] != nil else {
            return
        }
        
        shouldComeToEnd = false
        scheduleDownload(configurationID: buildGroupingConfigurationID(itemID))
    }
    func scheduleAll() async {
        do {
            try await PersistenceManager.shared.authorization.waitForConnections()
        } catch {
            logger.error("Failed to schedule all for download: \(error)")
            return
        }
        
        shouldComeToEnd = false
        
        let configurations = await activeConfigurations
        
        for configuration in configurations {
            scheduleDownload(configurationID: configuration.id)
        }
        
        logger.info("Queued \(configurations.count) configurations for download")
    }
    
    // MARK: Events
    
    nonisolated func itemDidFinishPlaying(_ itemID: ItemIdentifier) async {
        if Defaults[.removeFinishedDownloads] {
            guard await PersistenceManager.shared.progress[itemID].isFinished else {
                return
            }
            
            do {
                try await PersistenceManager.shared.download.remove(itemID)
            } catch {
                logger.error("Failed to remove downloaded item \(itemID) after it finished playing: \(error)")
            }
        }
        
        if let associatedConfigurationIDs = await PersistenceManager.shared.keyValue[.associatedConfigurationIDs(itemID: itemID)], associatedConfigurationIDs.count > 0 {
            for configurationID in associatedConfigurationIDs {
                await scheduleDownload(configurationID: configurationID)
            }
        }
    }
    
    // MARK: Background-Task
    
    nonisolated var runsInExtendedBackgroundTask: Bool {
        get async {
            await PersistenceManager.shared.keyValue[.runExtendedBackgroundTask] == true
        }
    }
    func resetRunsInExtendedBackgroundTask() async throws {
        try await PersistenceManager.shared.keyValue.set(.runExtendedBackgroundTask, nil)
    }
    
    nonisolated func scheduleBackgroundTask(shouldWait: Bool) async {
        guard await BGTaskScheduler.shared.pendingTaskRequests().first(where: {$0.identifier == Self.BACKGROUND_TASK_IDENTIFIER }) == nil else {
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
                try? await PersistenceManager.shared.keyValue.set(.runExtendedBackgroundTask, nil)
            }
        } else {
            request = BGAppRefreshTaskRequest(identifier: Self.BACKGROUND_TASK_IDENTIFIER)
            
            if shouldWait {
                request.earliestBeginDate =  .now.advanced(by: 60 * 60 * 3)
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
                try? await PersistenceManager.shared.keyValue.set(.runExtendedBackgroundTask, true)
            }
        }
        
        // Detect finish
        
        RFNotification[.convenienceDownloadIteration].subscribe { [weak self] in
            Task {
                guard let currentProgress = await self?.currentProgress, currentProgress >= 1 else {
                    return
                }
                
                await self?.scheduleBackgroundTask(shouldWait: true)
                task.setTaskCompleted(success: true)
            }
        }
        
        // Schedule task
        
        Task {
            await self.scheduleAll()
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
                    Defaults[.enableListenNowDownloads] = false
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
                        #warning("uhujh")
                        return []
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

private func buildGroupingConfigurationID(_ itemID: ItemIdentifier) -> String {
    "grouping-\(itemID)"
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func convenienceDownloadRetrieval(itemID: ItemIdentifier) -> Key<PersistenceManager.ConvenienceDownloadSubsystem.GroupingRetrieval> {
        convenienceDownloadRetrieval(configurationID: buildGroupingConfigurationID(itemID))
    }
    static func convenienceDownloadRetrieval(configurationID: String) -> Key<PersistenceManager.ConvenienceDownloadSubsystem.GroupingRetrieval> {
        .init(identifier: "convenienceDownloadRetrieval-\(configurationID)", cluster: RETRIEVALS_KEY_VALUE_CLUSTER, isCachePurgeable: false)
    }
    
    static func downloadedItemIDs(itemID: ItemIdentifier) -> Key<Set<ItemIdentifier>> {
        downloadedItemIDs(configurationID: buildGroupingConfigurationID(itemID))
    }
    static func downloadedItemIDs(configurationID: String) -> Key<Set<ItemIdentifier>> {
        .init(identifier: "downloadedItemIDs-\(configurationID)", cluster: DOWNLOADED_KEY_VALUE_CLUSTER, isCachePurgeable: false)
    }
    
    static func associatedConfigurationIDs(itemID: ItemIdentifier) -> Key<Set<String>> {
        .init(identifier: "associatedConfigurationIDs-\(itemID)", cluster: ASSOCIATED_KEY_VALUE_CLUSTER, isCachePurgeable: false)
    }
    
    static var runExtendedBackgroundTask: Key<Bool> {
        .init(identifier: "runExtendedBackgroundTask", cluster: "_", isCachePurgeable: true)
    }
}
