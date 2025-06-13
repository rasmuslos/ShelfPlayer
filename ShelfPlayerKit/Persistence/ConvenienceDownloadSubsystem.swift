//
//  ConvenienceDownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 03.05.25.
//

import Foundation
import OSLog
import Defaults
import RFNotifications

let LISTEN_NOW_CONFIGURATION_ID = "listen-now"
let KEY_VALUE_CLUSTER = "convenienceDownloadRetrievals"

extension PersistenceManager {
    public final actor ConvenienceDownloadSubsystem {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ConvenienceDownloadSubsystem")
        
        var task: Task<Void, Never>?
        var pendingConfigurationIDs = Set<String>()
        
        init() {
            RFNotification[.listenNowItemsChanged].subscribe { [weak self] in
                guard Defaults[.enableListenNowDownloads] else {
                    return
                }
                
                Task {
                    await self?.scheduleDownload(configurationID: LISTEN_NOW_CONFIGURATION_ID)
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
            
            if let downloaded = await PersistenceManager.shared.keyValue[.downloadedItemIDs(itemID: itemID)] {
                for itemID in downloaded {
                    await remove(itemID: itemID, configurationID: configurationID)
                }
                
                do {
                    try await PersistenceManager.shared.keyValue.set(.downloadedItemIDs(itemID: itemID), nil)
                } catch {
                    logger.error("Failed to remove convenience download configuration for item \(itemID): \(error)")
                }
            }
            
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
            return
        }
        
        let configurationID = pendingConfigurationIDs.removeFirst()
        
        task = .detached {
            await self.download(configurationID: configurationID)
            
            await self.unscheduleTask()
            await self.scheduleTask()
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
            
            logger.info("Finished evaluating downloads for \(configurationID). D: \(downloaded.count), Q: \(queuedDownloads.count), O: \(orphanedDownloads.count)")
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
    nonisolated func resolveItemID(from configurationID: String) -> ItemIdentifier? {
        guard configurationID.starts(with: "grouping-") else {
            return nil
        }
        
        let itemIDDescription = configurationID[configurationID.index(after: configurationID.firstIndex(of: "-")!)..<configurationID.endIndex]
        return ItemIdentifier(String(itemIDDescription))
    }
}

public extension PersistenceManager.ConvenienceDownloadSubsystem {
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
    }
    
    nonisolated var activeConfigurations: [ConvenienceDownloadConfiguration] {
        get async {
            var configurations = [ConvenienceDownloadConfiguration]()
            
            if Defaults[.enableListenNowDownloads] {
                configurations.append(.listenNow)
            }
            
            let retrievals = await PersistenceManager.shared.keyValue.entities(cluster: KEY_VALUE_CLUSTER, type: GroupingRetrieval.self)
            
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
    
    // MARK: Schedule
    
    func scheduleUpdate(itemID: ItemIdentifier) async {
        guard await PersistenceManager.shared.keyValue[.convenienceDownloadRetrieval(itemID: itemID)] != nil else {
            return
        }
        
        scheduleDownload(configurationID: buildGroupingConfigurationID(itemID))
    }
    func scheduleAll() async {
        if await PersistenceManager.shared.authorization.connections.isEmpty {
            try? await PersistenceManager.shared.authorization.fetchConnections()
        }
        
        let configurations = await activeConfigurations
        
        for configuration in configurations {
            scheduleDownload(configurationID: configuration.id)
        }
        
        logger.info("Queued \(configurations.count) configurations for download")
    }
    
    // MARK: Events
    
    nonisolated func itemDidFinishPlaying(_ itemID: ItemIdentifier) async {
        if let associatedConfigurationIDs = await PersistenceManager.shared.keyValue[.associatedConfigurationIDs(itemID: itemID)], associatedConfigurationIDs.count > 0 {
            for configurationID in associatedConfigurationIDs {
                await scheduleDownload(configurationID: configurationID)
            }
        } else if Defaults[.removeFinishedDownloads] {
            print(await PersistenceManager.shared.progress[itemID])
            guard await PersistenceManager.shared.progress[itemID].isFinished else {
                return
            }
            
            do {
                try await PersistenceManager.shared.download.remove(itemID)
            } catch {
                logger.error("Failed to remove downloaded item \(itemID) after it finished playing: \(error)")
            }
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
                            default:
                                throw ConvenienceDownloadError.invalidItemType
                        }
                        
                        let items = try await strategy.resolve(cutoff: nil)
                        let result: [PlayableItem]
                        
                        switch retrieval {
                            case .all:
                                result = items
                            case .amount(let count):
                                result = Array(items[0..<count])
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
                        return await ShelfPlayerKit.listenNowItems
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
        .init(identifier: "convenienceDownloadRetrieval-\(configurationID)", cluster: KEY_VALUE_CLUSTER, isCachePurgeable: false)
    }
    
    static func downloadedItemIDs(itemID: ItemIdentifier) -> Key<Set<ItemIdentifier>> {
        downloadedItemIDs(configurationID: buildGroupingConfigurationID(itemID))
    }
    static func downloadedItemIDs(configurationID: String) -> Key<Set<ItemIdentifier>> {
        .init(identifier: "downloadedItemIDs-\(configurationID)", cluster: "downloadedItemIDs", isCachePurgeable: false)
    }
    
    static func associatedConfigurationIDs(itemID: ItemIdentifier) -> Key<Set<String>> {
        .init(identifier: "associatedConfigurationIDs-\(itemID)", cluster: "associatedConfigurationIDs", isCachePurgeable: false)
    }
}
