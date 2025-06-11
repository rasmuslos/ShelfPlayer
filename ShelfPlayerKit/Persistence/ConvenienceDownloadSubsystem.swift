//
//  ConvenienceDownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 03.05.25.
//

import Foundation
import OSLog
import Defaults

let LISTEN_NOW_CONFIGURATION_ID = "listen-now"
let KEY_VALUE_CLUSTER = "convinienceDownloadRetreivals"

private typealias ConvenienceDownloadReleation = SchemaV2.PersistedConvenienceDownloadReleation

extension PersistenceManager {
    public final actor ConvenienceDownloadSubsystem {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ConversienceDownloadSubsystem")
        
        var task: Task<Void, Never>?
        var pendingConfigurationIDs = Set<String>()
        
        func sheduleDownload(configuration: ConvenienceDownloadConfiguration) {
            pendingConfigurationIDs.insert(configuration.id)
            sheduleTask()
        }
        nonisolated func cleanupOrphanedDownloads() async {
            
        }
        
        // MARK: Task
        
        func sheduleTask() {
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
                
                task = .detached {
                    await self.cleanupOrphanedDownloads()
                    await self.unschduleTask()
                }
                
                return
            }
            
            let configurationID = pendingConfigurationIDs.removeFirst()
            
            task = .detached {
                await self.download(configurationID: configurationID)
                
                await self.unschduleTask()
                await self.sheduleTask()
            }
        }
        func unschduleTask() {
            task = nil
        }
        
        // MARK: Download
        
        func download(configurationID: String) async {
            guard let configuration = try? await resolveConfiguration(id: configurationID) else {
                logger.error("Failed to resolve configuration: \(configurationID)")
                return
            }
            
            logger.info("Begin convinience download of configuration: \(configurationID)")
            
            print(configuration)
        }
        func resolveConfiguration(id: String) async throws -> ConvenienceDownloadConfiguration {
            if id == LISTEN_NOW_CONFIGURATION_ID {
                return .listenNow
            }
            
            if let itemID = resolveItemID(from: id), let retreival = await PersistenceManager.shared.keyValue[.convinienceDownloadRetreival(configurationID: id)] {
                return .grouping(itemID, retreival)
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
    func retreival(for itemID: ItemIdentifier) async -> GroupingRetrieval? {
        await PersistenceManager.shared.keyValue[.convinienceDownloadRetreival(itemID: itemID)]
    }
    nonisolated func setRetreival(for itemID: ItemIdentifier, retreival: GroupingRetrieval?) async throws {
        if let retreival {
            let configuration = ConvenienceDownloadConfiguration.grouping(itemID, retreival)
            try await PersistenceManager.shared.keyValue.set(.convinienceDownloadRetreival(configurationID: configuration.id), retreival)
            
            await sheduleDownload(configuration: configuration)
        } else {
            try await PersistenceManager.shared.keyValue.set(.convinienceDownloadRetreival(itemID: itemID), nil)
            await cleanupOrphanedDownloads()
        }
    }
    
    var activeConfigurations: [ConvenienceDownloadConfiguration] {
        get async {
            var configurations = [ConvenienceDownloadConfiguration]()
            
            if Defaults[.enableListenNowDownloads] {
                configurations.append(.listenNow)
            }
         
            let retreivals = await PersistenceManager.shared.keyValue.entities(cluster: KEY_VALUE_CLUSTER, type: GroupingRetrieval.self)
            
            configurations += retreivals.compactMap { (id, retreival) -> ConvenienceDownloadConfiguration? in
                guard let itemID = resolveItemID(from: id) else {
                    return nil
                }
                
                return .grouping(itemID, retreival)
            }
            
            return configurations
        }
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
                case .grouping(let itemID, let reteival):
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
                    
                    switch reteival {
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
    static func convinienceDownloadRetreival(itemID: ItemIdentifier) -> Key<PersistenceManager.ConvenienceDownloadSubsystem.GroupingRetrieval> {
        convinienceDownloadRetreival(configurationID: buildGroupingConfigurationID(itemID))
    }
    static func convinienceDownloadRetreival(configurationID: String) -> Key<PersistenceManager.ConvenienceDownloadSubsystem.GroupingRetrieval> {
        .init(identifier: "convinienceDownloadRetreival-\(configurationID)", cluster: KEY_VALUE_CLUSTER, isCachePurgeable: false)
    }
}
