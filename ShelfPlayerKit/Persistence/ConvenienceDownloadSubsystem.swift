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
                    await self?.scheduleDownload(configuration: .listenNow)
                }
            }
        }
        
        func scheduleDownload(configuration: ConvenienceDownloadConfiguration) {
            pendingConfigurationIDs.insert(configuration.id)
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
                logger.info("Finished running convenience download task. Cleaning up orphaned downloads...")
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
        
        func download(configurationID: String) async {
            guard let configuration = try? await resolveConfiguration(id: configurationID) else {
                logger.error("Failed to resolve configuration: \(configurationID)")
                return
            }
            
            logger.info("Begin convenience download of configuration: \(configurationID)")
            
            do {
                let items = try await configuration.items
                let itemIDs = Set(items.map(\.id))
                let downloaded = await PersistenceManager.shared.keyValue[.downloadedItemIDs(configurationID: configurationID)] ?? []
                
                let missingDownloads = itemIDs.subtracting(downloaded)
                var queuedDownloads = Set<ItemIdentifier>()
                
                if missingDownloads.isEmpty {
                    logger.info("Nothing to download for configuration: \(configurationID)")
                } else {
                    for itemID in missingDownloads {
                        do {
                            try await PersistenceManager.shared.download.download(itemID)
                            queuedDownloads.insert(itemID)
                        } catch {
                            logger.error("Failed to download item: \(error)")
                        }
                    }
                }
                
                let updatedDownloadedIDs = downloaded.intersection(itemIDs).union(queuedDownloads)
                let orphanedDownloads = downloaded.subtracting(updatedDownloadedIDs)
                
                try await PersistenceManager.shared.keyValue.set(.downloadedItemIDs(configurationID: configurationID), updatedDownloadedIDs)
                
                if !orphanedDownloads.isEmpty {
                    for itemID in orphanedDownloads {
                        do {
                            try await PersistenceManager.shared.download.remove(itemID)
                        } catch {
                            logger.error("Failed to remove orphaned download item: \(error)")
                        }
                    }
                }
            } catch {
                logger.error("Failed to download configuration: \(error)")
            }
        }
        func resolveConfiguration(id: String) async throws -> ConvenienceDownloadConfiguration {
            if id == LISTEN_NOW_CONFIGURATION_ID {
                return .listenNow
            }
            
            if let itemID = resolveItemID(from: id), let retrieval = await PersistenceManager.shared.keyValue[.convenienceDownloadRetrieval(configurationID: id)] {
                return .grouping(itemID, retrieval)
            }
            
            throw ConvenienceDownloadError.notFound
        }
        func resolveItemID(from configurationID: String) -> ItemIdentifier? {
            guard configurationID.starts(with: "grouping-") else {
                return nil
            }
            
            let itemIDDescription = configurationID[configurationID.index(after: configurationID.firstIndex(of: "-")!)..<configurationID.endIndex]
            return ItemIdentifier(String(itemIDDescription))
        }
    }
}

public extension PersistenceManager.ConvenienceDownloadSubsystem {
    func retrieval(for itemID: ItemIdentifier) async -> GroupingRetrieval? {
        await PersistenceManager.shared.keyValue[.convenienceDownloadRetrieval(itemID: itemID)]
    }
    nonisolated func setRetrieval(for itemID: ItemIdentifier, retrieval: GroupingRetrieval?) async throws {
        if let retrieval {
            let configuration = ConvenienceDownloadConfiguration.grouping(itemID, retrieval)
            try await PersistenceManager.shared.keyValue.set(.convenienceDownloadRetrieval(configurationID: configuration.id), retrieval)
            
            await scheduleDownload(configuration: configuration)
        } else {
            try await PersistenceManager.shared.keyValue.set(.convenienceDownloadRetrieval(itemID: itemID), nil)
            
            if let downloaded = await PersistenceManager.shared.keyValue[.downloadedItemIDs(itemID: itemID)] {
                for itemID in downloaded {
                    do {
                        try await PersistenceManager.shared.download.remove(itemID)
                    } catch {
                        logger.error("Failed to remove downloaded item \(itemID): \(error)")
                    }
                }
                
                try await PersistenceManager.shared.keyValue.set(.downloadedItemIDs(itemID: itemID), nil)
            }
        }
    }
    
    var activeConfigurations: [ConvenienceDownloadConfiguration] {
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
    
    func scheduleUpdate(itemID: ItemIdentifier) async {
        guard let retrieval = await PersistenceManager.shared.keyValue[.convenienceDownloadRetrieval(itemID: itemID)] else {
            return
        }
        
        scheduleDownload(configuration: .grouping(itemID, retrieval))
    }
    func scheduleAll() async {
        if await PersistenceManager.shared.authorization.connections.isEmpty {
            try? await PersistenceManager.shared.authorization.fetchConnections()
        }
        
        let configurations = await activeConfigurations
        
        for configuration in configurations {
            scheduleDownload(configuration: configuration)
        }
        
        logger.info("Queued \(configurations.count) configurations for download")
    }
    
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
}
