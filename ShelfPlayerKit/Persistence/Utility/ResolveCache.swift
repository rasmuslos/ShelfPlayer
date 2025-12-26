//
//  ResolveCache.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.05.25.
//

import Foundation
import OSLog
import RFNotifications

private let TTL_CLUSTER = "ttls"
private let ITEM_TYPE_CLUSTER = "itemTypes"

public actor ResolveCache: Sendable {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ResolveCache")
    let cachePath = ShelfPlayerKit.cacheDirectoryURL.appending(path: "Items")
    
    let memoryCache = NSCache<NSString, Item>()
    
    private init() {
        memoryCache.countLimit = 760
        
        RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
            Task {
                await self?.invalidate()
            }
        }
    }
    
    private func invalidate() {
        memoryCache.removeAllObjects()
    }
    
    private enum ResolveError: Error {
        case offline
        
        case missingEpisode
        case missingNarrator
        case missingGroupingID
    }
    
    public nonisolated static let shared = ResolveCache()
}

public extension ResolveCache {
    func resolve(_ itemID: ItemIdentifier) async throws -> Item {
        if let downloaded = await PersistenceManager.shared.download[itemID] {
            return downloaded
        } else if let diskCached = await diskCached(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID) {
            return diskCached
        }
        
        guard await !OfflineMode.shared.isEnabled else {
            throw ResolveError.offline
        }
        
        let item: Item
        
        switch itemID.type {
            case .audiobook:
                item = try await ABSClient[itemID.connectionID].audiobook(with: itemID)
            case .author:
                item = try await ABSClient[itemID.connectionID].author(with: itemID)
            case .narrator:
                let narrators = try await ABSClient[itemID.connectionID].narrators(from: itemID.libraryID)
                let narrator = narrators.first {
                    $0.id == itemID
                }
                
                guard let narrator else {
                    throw ResolveError.missingNarrator
                }
                
                item = narrator
            case .series:
                item = try await ABSClient[itemID.connectionID].series(with: itemID)
            case .podcast:
                item = try await resolveOnlinePodcast(primaryID: itemID.primaryID, connectionID: itemID.connectionID).0
            case .episode:
                guard let groupingID = itemID.groupingID else {
                    throw ResolveError.missingGroupingID
                }
                
                item = try await resolveOnlineEpisode(primaryID: itemID.primaryID, groupingID: groupingID, connectionID: itemID.connectionID)
            case .collection, .playlist:
                item = try await ABSClient[itemID.connectionID].collection(with: itemID)
        }
        
        if !(item.id.type == .episode || item.id.type == .podcast) {
            store(item: item)
        }
        
        return item
    }
    func resolve(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws -> PlayableItem {
        if let downloaded = await PersistenceManager.shared.download.item(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) {
            return downloaded
        } else if let diskCached = await diskCached(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) as? PlayableItem {
            return diskCached
        }
        
        guard await !OfflineMode.shared.isEnabled else {
            throw ResolveError.offline
        }
        
        if let groupingID {
            return try await resolveOnlineEpisode(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
        } else {
            let audiobook = try await ABSClient[connectionID].audiobook(primaryID: primaryID)
            
            store(item: audiobook)
            return audiobook
        }
    }
    func resolve(primaryID: ItemIdentifier.PrimaryID, connectionID: ItemIdentifier.ConnectionID) async throws -> Podcast {
        if let downloaded = await PersistenceManager.shared.download.podcast(primaryID: primaryID, connectionID: connectionID) {
            return downloaded
        } else if let diskCached = await diskCached(primaryID: primaryID, groupingID: nil, connectionID: connectionID) as? Podcast {
            return diskCached
        }
        
        guard await !OfflineMode.shared.isEnabled else {
            throw ResolveError.offline
        }
        
        return try await resolveOnlinePodcast(primaryID: primaryID, connectionID: connectionID).0
    }
}

private extension ResolveCache {
    func resolveOnlinePodcast(primaryID: ItemIdentifier.PrimaryID, connectionID: ItemIdentifier.ConnectionID) async throws -> (Podcast, [Episode]) {
        let (podcast, episodes) = try await ABSClient[connectionID].podcast(with: primaryID)
        
        store(item: podcast)
        
        for episode in episodes {
            store(item: episode)
        }
        
        return (podcast, episodes)
    }
    func resolveOnlineEpisode(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID, connectionID: ItemIdentifier.ConnectionID) async throws -> Episode {
        let episodes = try await resolveOnlinePodcast(primaryID: primaryID, connectionID: connectionID).1
        let episode = episodes.first {
            $0.id.primaryID == primaryID
        }
        
        guard let episode else {
            throw ResolveError.missingEpisode
        }
        
        return episode
    }
}

public extension ResolveCache {
    func flush() async {
        memoryCache.removeAllObjects()
        
        do {
            try FileManager.default.removeItem(at: cachePath)
        } catch {
            logger.error("Error removing cache directory: \(error)")
        }
        
        do {
            try await PersistenceManager.shared.keyValue.remove(cluster: TTL_CLUSTER)
            try await PersistenceManager.shared.keyValue.remove(cluster: ITEM_TYPE_CLUSTER)
        } catch {
            logger.error("Failed to clear item type and TTL clusters: \(error)")
        }
    }
    func invalidate(itemID: ItemIdentifier) async {
        memoryCache.removeObject(forKey: memoryCacheKey(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID))
        
        do {
            try FileManager.default.removeItem(at: diskPath(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID))
        } catch {
            logger.fault("Failed to remove cached item: \(error)")
        }
    }
}

// MARK: Disk & Memory cache

private extension ResolveCache {
    func diskPath(connectionID: ItemIdentifier.ConnectionID) -> URL {
        cachePath
            .appending(path: connectionID)
    }
    func diskPath(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> URL {
        diskPath(connectionID: connectionID)
            .appending(path: "\(primaryID)_\(groupingID ?? "-")")
    }
    func memoryCacheKey(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> NSString {
        NSString(string: "\(connectionID)_\(primaryID)_\(groupingID ?? "-")")
    }
    
    func diskCached(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async -> Item? {
        if let memoryCached = memoryCache.object(forKey: memoryCacheKey(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)) {
            return memoryCached
        }
        
        let diskPath = diskPath(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
        
        guard FileManager.default.fileExists(atPath: diskPath.path) else {
            return nil
        }
        
        let content: Data
        
        do {
            content = try Data(contentsOf: diskPath)
        } catch {
            logger.error("Failed to read the cached file: \(error)")
            return nil
        }
        
        guard let result = try? JSONDecoder().decode(DiskCachedItem.self, from: content).item else {
            logger.error("Failed to decode the cached file")
            
            do {
                try FileManager.default.removeItem(at: diskPath)
            } catch {
                logger.error("Failed to delete the corrupted file: \(error)")
            }
            
            return nil
        }
        
        logger.info("Using disk cache for item \(result.id)")
        
        return result
    }
    func store(item: Item) {
        let primaryID = item.id.primaryID
        let groupingID = item.id.groupingID
        let connectionID = item.id.connectionID
        
        memoryCache.setObject(item, forKey: memoryCacheKey(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID))
        
        let cached = DiskCachedItem(item: item)
        
        do {
            let encoded = try JSONEncoder().encode(cached)
            
            try FileManager.default.createDirectory(at: diskPath(connectionID: connectionID), withIntermediateDirectories: true)
            try encoded.write(to: diskPath(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID))
            
            logger.info("Stored item \(item.id) on disk")
        } catch {
            logger.error("Failure to cache item: \(error)")
        }
    }
}

private struct DiskCachedItem: Codable {
    let itemID: ItemIdentifier
    
    let audiobook: Audiobook?
    let series: Series?
    
    let episode: Episode?
    let podcast: Podcast?
    
    let person: Person?
    let collection: ItemCollection?
    
    init(item: Item) {
        itemID = item.id
        
        audiobook = item as? Audiobook
        series = item as? Series
        
        episode = item as? Episode
        podcast = item as? Podcast
        
        person = item as? Person
        collection = item as? ItemCollection
    }
    
    var item: Item? {
        get {
            audiobook ?? series ?? episode ?? podcast ?? person ?? collection
        }
    }
}
