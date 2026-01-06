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
    
    var resolveItemID = [ItemIdentifier: Task<Item, Error>]()
    var resolvePlayableItem = [NSString: Task<PlayableItem, Error>]()
    var resolvePodcast = [NSString: Task<(Podcast, [Episode]), Error>]()
    
    private init() {
        memoryCache.countLimit = 760
        
        RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
            Task {
                await self?.invalidate()
            }
        }
    }
    
    private func invalidate() {
        resolveItemID.removeAll()
        resolvePlayableItem.removeAll()
        resolvePodcast.removeAll()
        
        memoryCache.removeAllObjects()
    }
    
    private enum ResolveError: Error {
        case invalidDiskCached
        
        case missingEpisode
        case missingNarrator
        case missingGroupingID
    }
    
    public nonisolated static let shared = ResolveCache()
}

public extension ResolveCache {
    func resolve(_ itemID: ItemIdentifier) async throws -> Item {
        // ReferenceWritableKeyPath<ResolveCache, [K: Task<Item, Error>]> did not work

        if resolveItemID[itemID] == nil {
            resolveItemID[itemID] = .init {
                logger.info("Attempting to resolve item: \(itemID)")
                
                if let downloaded = await PersistenceManager.shared.download[itemID] {
                    return downloaded
                } else if let diskCached = await diskCached(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID) {
                    return diskCached
                }
                
                guard await !OfflineMode.shared.isEnabled else {
                    throw APIClientError.offline
                }
                
                logger.info("No downloaded or disk cached for \(itemID)")
                
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
        }
        
        return try await resolveItemID[itemID]!.value
    }
    func resolve(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws -> PlayableItem {
        let cacheKey = memoryCacheKey(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
        
        if resolvePlayableItem[cacheKey] == nil {
            resolvePlayableItem[cacheKey] = .init {
                logger.info("Attempting to resolve playable item: \(primaryID) \(String(describing: groupingID)) \(connectionID)")
                
                if let downloaded = await PersistenceManager.shared.download.item(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) {
                    return downloaded
                } else if let diskCached = await diskCached(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) as? PlayableItem {
                    return diskCached
                }
                
                logger.info("No downloaded or disk cached for playable item: \(primaryID) \(String(describing: groupingID)) \(connectionID)")
                
                guard await !OfflineMode.shared.isEnabled else {
                    throw APIClientError.offline
                }
                
                if let groupingID {
                    return try await resolveOnlineEpisode(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                } else {
                    let audiobook = try await ABSClient[connectionID].audiobook(primaryID: primaryID)
                    
                    store(item: audiobook)
                    return audiobook
                }
            }
        }
        
        return try await resolvePlayableItem[cacheKey]!.value
    }
    func resolve(primaryID: ItemIdentifier.PrimaryID, connectionID: ItemIdentifier.ConnectionID) async throws -> Podcast {
        logger.info("Attempting to resolve podcast: \(primaryID) \(connectionID)")
        
        if let downloaded = await PersistenceManager.shared.download.podcast(primaryID: primaryID, connectionID: connectionID) {
            return downloaded
        } else if let diskCached = await diskCached(primaryID: primaryID, groupingID: nil, connectionID: connectionID) as? Podcast {
            return diskCached
        }
        
        logger.info("No downloaded or disk cached for podcast: \(primaryID) \(connectionID)")
        
        guard await !OfflineMode.shared.isEnabled else {
            throw APIClientError.offline
        }
        
        return try await resolveOnlinePodcast(primaryID: primaryID, connectionID: connectionID).0
    }
}

private extension ResolveCache {
    func resolveOnlinePodcast(primaryID: ItemIdentifier.PrimaryID, connectionID: ItemIdentifier.ConnectionID) async throws -> (Podcast, [Episode]) {
        let cacheKey = memoryCacheKey(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
        
        if resolvePodcast[cacheKey] == nil {
            resolvePodcast[cacheKey] = .init {
                let (podcast, episodes) = try await ABSClient[connectionID].podcast(with: primaryID)
                
                store(item: podcast)
                
                for episode in episodes {
                    store(item: episode)
                }
                
                return (podcast, episodes)
            }
        }
        
        return try await resolvePodcast[cacheKey]!.value
    }
    func resolveOnlineEpisode(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID, connectionID: ItemIdentifier.ConnectionID) async throws -> Episode {
        let episodes = try await resolveOnlinePodcast(primaryID: groupingID, connectionID: connectionID).1
        let episode = episodes.first {
            $0.id.primaryID == primaryID
        }
        
        guard let episode else {
            throw ResolveError.missingEpisode
        }
        
        return episode
    }
}

// MARK: Helper

public extension ResolveCache {
    static func nextGroupingItem(_ itemID: ItemIdentifier) async throws -> PlayableItem {
        switch itemID.type {
            case .series:
                guard let audiobook = try await ResolvedUpNextStrategy.series(itemID).resolve(cutoff: nil).first else {
                    throw APIClientError.notFound
                }
                
                return audiobook
            case .podcast:
                guard let episode = try await ResolvedUpNextStrategy.podcast(itemID).resolve(cutoff: nil).first else {
                    throw APIClientError.notFound
                }
                
                return episode
            case .collection, .playlist:
                guard let item = try await ResolvedUpNextStrategy.collection(itemID).resolve(cutoff: nil).first else {
                    throw APIClientError.notFound
                }
                
                return item
            default:
                throw APIClientError.invalidItemType
        }
    }
}

public extension ResolveCache {
    func flush() async {
        resolveItemID.removeAll()
        resolvePlayableItem.removeAll()
        resolvePodcast.removeAll()
        
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
    func invalidate(itemID: ItemIdentifier) {
        let cacheKey = memoryCacheKey(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
        
        resolveItemID.removeValue(forKey: itemID)
        resolvePlayableItem.removeValue(forKey: cacheKey)
        resolvePodcast.removeValue(forKey: cacheKey)
        
        memoryCache.removeObject(forKey: cacheKey)
        
        do {
            try FileManager.default.removeItem(atPath: diskPath(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID).relativePath)
        } catch {
            logger.error("Failed to remove cached item: \(error)")
        }
        
        if itemID.type == .episode {
            invalidate(itemID: ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(itemID))
        }
    }
}

// MARK: Disk & Memory cache

private extension ResolveCache {
    func memoryCacheKey(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> NSString {
        NSString(string: "\(connectionID)_\(primaryID)_\(groupingID ?? "-")")
    }
    
    func diskPath(connectionID: ItemIdentifier.ConnectionID) -> URL {
        cachePath
            .appending(path: connectionID.urlSafe)
    }
    func diskPath(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> URL {
        diskPath(connectionID: connectionID)
            .appending(path: "\(primaryID)_\(groupingID ?? "-")")
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
        
        do {
            guard let result = try JSONDecoder().decode(DiskCachedItem.self, from: content).item else {
                throw ResolveError.invalidDiskCached
            }
            
            logger.info("Using disk cache for item \(result.id)")
            return result
        } catch {
            logger.error("Failed to decode the cached file: \(error)")
            
            do {
                try FileManager.default.removeItem(at: diskPath)
            } catch {
                logger.error("Failed to delete the corrupted file: \(error)")
            }
            
            return nil
        }
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

