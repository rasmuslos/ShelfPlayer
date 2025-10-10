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
    
    private var unavailableItemIDs = [(ItemIdentifier.PrimaryID, ItemIdentifier.GroupingID?, ItemIdentifier.ConnectionID)]()
    private var resolvingItemIDs = [(ItemIdentifier.PrimaryID, ItemIdentifier.GroupingID?, ItemIdentifier.ConnectionID)]()
    
    private var cache = [ItemIdentifier: Item]()
    private var episodeCache = [ItemIdentifier: [Episode]]()
    
    private init() {
        RFNotification[.changeOfflineMode].subscribe { [weak self] _ in
            Task {
                await self?.invalidate()
            }
        }
    }
    
    func resolve(_ itemID: ItemIdentifier) async throws -> (Item, [Episode]) {
        try await waitForResolvingItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
        
        if let cached = cache[itemID] {
            if itemID.type == .podcast, episodeCache[itemID]?.isEmpty != false {
                logger.info("Podcast \(cached.name) is cached but has no episodes, attempting to fetch them")
                
                beginResolvingItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
                
                let episodes: [Episode]
                
                do {
                    episodes = try await ABSClient[itemID.connectionID].episodes(from: itemID)
                } catch {
                    episodes = try await PersistenceManager.shared.download.episodes(from: itemID)
                }
                
                episodeCache[itemID] = episodes
                
                resolvedItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
            }
            
            return (cached, episodeCache[itemID] ?? [])
        }
        if let diskCached = try? await checkDiskCached(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID) {
            if let groupingID = itemID.groupingID, let episodes = try? await diskCachedEpisodes(groupingID: groupingID, connectionID: itemID.connectionID) {
                return (diskCached, episodes)
            }
            
            return (diskCached, [])
        }
        
        beginResolvingItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
        
        let item: Item
        let episodes: [Episode]
        
        do {
            if let downloaded = await PersistenceManager.shared.download[itemID] {
                item = downloaded
                
                if itemID.type == .podcast {
                    if let cached = episodeCache[itemID] {
                        episodes = cached
                    } else {
                        do {
                            episodes = try await ABSClient[itemID.connectionID].episodes(from: itemID)
                        } catch {
                            episodes = try await PersistenceManager.shared.download.episodes(from: itemID)
                        }
                    }
                } else {
                    episodes = []
                }
            } else {
                switch itemID.type {
                    case .audiobook:
                        item = try await ABSClient[itemID.connectionID].playableItem(itemID: itemID).0
                        episodes = []
                    case .author:
                        item = try await ABSClient[itemID.connectionID].author(with: itemID)
                        episodes = []
                    case .narrator:
                        let narrators = try await ABSClient[itemID.connectionID].narrators(from: itemID.libraryID)
                        
                        guard let narrator = narrators.first(where: { $0.id == itemID }) else {
                            throw ResolveError.notFound
                        }
                        
                        item = narrator
                        episodes = []
                    case .series:
                        item = try await ABSClient[itemID.connectionID].series(with: itemID)
                        episodes = []
                        
                    case .podcast:
                        (item, episodes) = try await ABSClient[itemID.connectionID].podcast(with: itemID)
                        episodeCache[item.id] = episodes
                    case .episode:
                        let (_, received) = try await resolve(ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(itemID))
                        
                        guard let episode = received.first(where: { $0.id == itemID }) else {
                            throw ResolveError.notFound
                        }
                        
                        item = episode
                        episodes = []
                        
                    case .collection, .playlist:
                        item = try await ABSClient[itemID.connectionID].collection(with: itemID)
                        episodes = []
                }
            }
        } catch {
            unavailableItemIDs.append((itemID.primaryID, itemID.groupingID, itemID.connectionID))
            resolvedItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
            
            throw ResolveError.notFound
        }
        
        cache[item.id] = item

        for episode in episodes {
            cache[episode.id] = episode
            await cacheToDisk(item: episode)
        }
        
        resolvedItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
        await cacheToDisk(item: item)
        
        return (item, episodes)
    }
    public func resolve(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws -> PlayableItem {
        try await waitForResolvingItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
        
        if let cached = cache.first(where: { $0.key.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }), let item = cached.value as? PlayableItem {
            return item
        }
        if let diskCached = try? await checkDiskCached(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) as? PlayableItem {
            return diskCached
        }
        
        beginResolvingItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
        
        do {
            if let item = await PersistenceManager.shared.download.item(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) {
                resolvedItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                return item
            }
                
            if let groupingID {
                let (_, episodes) = try await resolve(primaryID: groupingID, connectionID: connectionID)
                
                guard let episode = episodes.first(where: { $0.id.primaryID == primaryID }) else {
                    throw ResolveError.notFound
                }
                
                resolvedItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                
                return episode
            } else {
                let audiobook = try await ABSClient[connectionID].audiobook(primaryID: primaryID)
                
                cache[audiobook.id] = audiobook
                resolvedItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                await cacheToDisk(item: audiobook)
                
                return audiobook
            }
        } catch {
            unavailableItemIDs.append((primaryID, groupingID, connectionID))
            resolvedItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
            
            throw error
        }
    }
    public func resolve(primaryID: ItemIdentifier.PrimaryID, connectionID: ItemIdentifier.ConnectionID) async throws -> (Podcast, [Episode]) {
        try await waitForResolvingItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
        
        if let cached = cache.first(where: { $0.key.isEqual(primaryID: primaryID, groupingID: nil, connectionID: connectionID) }), let podcast = cached.value as? Podcast {
            return (podcast, episodeCache[podcast.id] ?? [])
        }
        
        beginResolvingItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
        
        do {
            if let podcast = await PersistenceManager.shared.download.podcast(primaryID: primaryID, connectionID: connectionID) {
                let episodes = try await PersistenceManager.shared.download.episodes(from: podcast.id)
                resolvedItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
                
                return (podcast, episodes)
            }
            
            let (podcast, episodes) = try await ABSClient[connectionID].podcast(with: primaryID)
            
            cache[podcast.id] = podcast
            episodeCache[podcast.id] = episodes
            
            for episode in episodes {
                cache[episode.id] = episode
                await cacheToDisk(item: episode)
            }
            
            resolvedItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
            await cacheToDisk(item: podcast)
            
            return (podcast, episodes)
        } catch {
            unavailableItemIDs.append((primaryID, nil, connectionID))
            resolvedItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
            
            throw error
        }
    }
    
    private func invalidate() {
        unavailableItemIDs.removeAll()
    }
    
    public func flush() async {
        cache.removeAll()
        episodeCache.removeAll()
        
        resolvingItemIDs.removeAll()
        unavailableItemIDs.removeAll()
        
        do {
            try FileManager.default.removeItem(at: ShelfPlayerKit.cacheDirectoryURL)
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
    public func invalidate(itemID: ItemIdentifier) async {
        cache[itemID] = nil
        episodeCache[itemID] = nil
        
        if itemID.type == .episode {
            let podcastID = ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(itemID)
            episodeCache[podcastID] = nil
        }
        
        await removeDiskCached(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
    }
    
    private enum ResolveError: Error {
        case notFound
        case unavailable
        case expired
    }
    
    public nonisolated static let shared = ResolveCache()
}

private extension ResolveCache {
    func waitForResolvingItem(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws {
        guard !unavailableItemIDs.contains(where: { $0.0 == primaryID && $0.1 == groupingID && $0.2 == connectionID }) else {
            throw ResolveError.unavailable
        }
        
        while resolvingItemIDs.contains(where: { $0.0 == primaryID && $0.1 == groupingID && $0.2 == connectionID }) {
            try await Task.sleep(for: .seconds(0.4))
        }
    }
    func beginResolvingItem(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) {
        resolvingItemIDs.append((primaryID, groupingID, connectionID))
    }
    
    func resolvedItem(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) {
        resolvingItemIDs.removeAll(where: {  $0.0 == primaryID && $0.1 == groupingID && $0.2 == connectionID })
    }
}

private extension ResolveCache {
    func diskPath(connectionID: ItemIdentifier.ConnectionID) -> URL {
        var base = ShelfPlayerKit.cacheDirectoryURL
        
        base.append(path: "Items")
        base.append(path: connectionID.replacing("/", with: "_"))
        
        return base
    }
    func diskPath(groupingID: ItemIdentifier.GroupingID, connectionID: ItemIdentifier.ConnectionID) -> URL {
        diskPath(connectionID: connectionID).appending(path: groupingID)
    }
    func diskPath(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> URL {
        var base: URL
        
        if let groupingID {
            base = diskPath(groupingID: groupingID, connectionID: connectionID)
        } else {
            base = diskPath(connectionID: connectionID)
        }
        
        try! FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        
        base.append(path: "\(primaryID).json")
        
        return base
    }
    func diskCachedEpisodes(groupingID: ItemIdentifier.GroupingID, connectionID: ItemIdentifier.ConnectionID) async throws -> [Episode] {
        let path = diskPath(groupingID: groupingID, connectionID: connectionID)
        var episodes = [Episode]()
        
        for file in try FileManager.default.contentsOfDirectory(atPath: path.relativePath) {
            guard let primaryID = file.split(separator: ".").first else {
                continue
            }
            
            guard let episode = try await checkDiskCached(primaryID: String(primaryID), groupingID: groupingID, connectionID: connectionID) as? Episode else {
                continue
            }
            
            episodes.append(episode)
        }
        
        return episodes
    }
    
    func checkDiskCached(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws -> Item {
        guard let ttl = await PersistenceManager.shared.keyValue[.ttl(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)],
              let itemType = await PersistenceManager.shared.keyValue[.itemType(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)] else {
            throw ResolveError.notFound
        }
        
        guard ttl > .now else {
            await removeDiskCached(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
            throw ResolveError.expired
        }
        
        let path = diskPath(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
        let data = try await URLSession.shared.data(from: path).0
        
        let type: Item.Type
        
        switch itemType {
            case .audiobook:
                type = Audiobook.self
            case .author, .narrator:
                type = Person.self
            case .series:
                type = Series.self
                
            case .episode:
                type = Episode.self
            case .podcast:
                type = Podcast.self
                
            case .collection, .playlist:
                type = ItemCollection.self
        }
        
        let item = try JSONDecoder().decode(type, from: data)
        
        cache[item.id] = item
        
        return item
    }
    func removeDiskCached(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async {
        do {
            try await PersistenceManager.shared.keyValue.set(.ttl(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID), nil)
            try await PersistenceManager.shared.keyValue.set(.itemType(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID), nil)
            
            let path = diskPath(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
            try FileManager.default.removeItem(at: path)
        } catch {
            logger.error("Failed to remove disk cached item: \(error)")
        }
    }
    func cacheToDisk(item: Item) async {
        guard item.id.type != .podcast else {
            return
        }
        
        await removeDiskCached(primaryID: item.id.primaryID, groupingID: item.id.groupingID, connectionID: item.id.connectionID)

        do {
            let oneMonth = 60 * 60 * 24 * 30
            let ttlVariation = Int.random(in: 1..<72) * 60 * 60
            let ttl = Date.now.addingTimeInterval(Double(oneMonth + ttlVariation))
            
            try await PersistenceManager.shared.keyValue.set(.ttl(primaryID: item.id.primaryID, groupingID: item.id.groupingID, connectionID: item.id.connectionID), ttl)
            try await PersistenceManager.shared.keyValue.set(.itemType(primaryID: item.id.primaryID, groupingID: item.id.groupingID, connectionID: item.id.connectionID), item.id.type)
            
            let path = diskPath(primaryID: item.id.primaryID, groupingID: item.id.groupingID, connectionID: item.id.connectionID)
            let data = try JSONEncoder().encode(item)
            
            FileManager.default.createFile(atPath: path.path(), contents: data)
        } catch {
            logger.error("Failed to cache item to disk: \(error)")
        }
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func ttl(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> Key<Date> {
        Key(identifier: "ttl_\(primaryID)_\(groupingID ?? "+")_\(connectionID)", cluster: TTL_CLUSTER, isCachePurgeable: false)
    }
    static func itemType(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> Key<ItemIdentifier.ItemType> {
        Key(identifier: "itemType_\(primaryID)_\(groupingID ?? "+")_\(connectionID)", cluster: ITEM_TYPE_CLUSTER, isCachePurgeable: false)
    }
}
