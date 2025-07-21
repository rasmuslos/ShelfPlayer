//
//  ResolveCache.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.05.25.
//

import Foundation
import OSLog

public actor ResolveCache: Sendable {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ResolveCache")
    
    private var resolvingItemIDs = [(ItemIdentifier.PrimaryID, ItemIdentifier.GroupingID?, ItemIdentifier.ConnectionID)]()
    
    private var cache = [ItemIdentifier: Item]()
    private var episodeCache = [ItemIdentifier: [Episode]]()
    
    func resolve(_ itemID: ItemIdentifier) async throws -> (Item, [Episode]) {
        try await waitForResolvingItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
        
        if let cached = cache[itemID] {
            return (cached, episodeCache[itemID] ?? [])
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
                        let podcast: Podcast
                        
                        (podcast, episodes) = try await ABSClient[itemID.connectionID].podcast(with: ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(itemID))
                        
                        cache[podcast.id] = podcast
                        episodeCache[podcast.id] = episodes
                        
                        guard let episode = episodes.first(where: { $0.id == itemID }) else {
                            throw ResolveError.notFound
                        }
                        
                        item = episode
                        
                    case .collection, .playlist:
                        item = try await ABSClient[itemID.connectionID].collection(with: itemID)
                        episodes = []
                }
            }
        } catch {
            resolvedItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
            throw ResolveError.notFound
        }
        
        cache[item.id] = item
        resolvedItem(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)

        for episode in episodes {
            cache[episode.id] = episode
        }
        
        return (item, episodes)
    }
    public func resolve(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws -> PlayableItem {
        try await waitForResolvingItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
        
        if let cached = cache.first(where: { $0.key.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }), let item = cached.value as? PlayableItem {
            return item
        }
        
        beginResolvingItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
        
        do {
            if let groupingID {
                let (podcast, episodes) = try await ABSClient[connectionID].podcast(with: groupingID)
                
                cache[podcast.id] = podcast
                episodeCache[podcast.id] = episodes
                
                for episode in episodes {
                    cache[episode.id] = episode
                }
                
                guard let episode = episodes.first(where: { $0.id.primaryID == primaryID }) else {
                    throw ResolveError.notFound
                }
                
                resolvedItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                
                return episode
            } else {
                let audiobook = try await ABSClient[connectionID].audiobook(primaryID: primaryID)
                
                cache[audiobook.id] = audiobook
                resolvedItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                
                return audiobook
            }
        } catch {
            resolvedItem(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
          throw error
        }
    }
    public func resolve(primaryID: ItemIdentifier.PrimaryID, connectionID: ItemIdentifier.ConnectionID) async throws -> Podcast {
        try await waitForResolvingItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
        
        if let cached = cache.first(where: { $0.key.isEqual(primaryID: primaryID, groupingID: nil, connectionID: connectionID) }), let podcast = cached.value as? Podcast {
            return podcast
        }
        
        beginResolvingItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
        
        do {
            let (podcast, episodes) = try await ABSClient[connectionID].podcast(with: primaryID)
            
            cache[podcast.id] = podcast
            episodeCache[podcast.id] = episodes
            
            for episode in episodes {
                cache[episode.id] = episode
            }
            
            resolvedItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
            
            return podcast
        } catch {
            resolvedItem(primaryID: primaryID, groupingID: nil, connectionID: connectionID)
            throw error
        }
    }
    
    public func invalidate() {
        cache.removeAll()
        episodeCache.removeAll()
    }
    public func invalidate(itemID: ItemIdentifier) {
        cache[itemID] = nil
        episodeCache[itemID] = nil
        
        if itemID.type == .episode {
            let podcastID = ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(itemID)
            episodeCache[podcastID] = nil
        }
    }
    
    private enum ResolveError: Error {
        case notFound
    }
    
    public nonisolated static let shared = ResolveCache()
}

private extension ResolveCache {
    func waitForResolvingItem(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws {
        while resolvingItemIDs.contains(where: {  $0.0 == primaryID && $0.1 == groupingID && $0.2 == connectionID }) || resolvingItemIDs.contains(where: {$0.0 == groupingID && $0.2 == connectionID }) {
            try await  Task.sleep(for: .seconds(0.4))
        }
    }
    func beginResolvingItem(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) {
        resolvingItemIDs.append((primaryID, groupingID, connectionID))
    }
    func resolvedItem(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) {
        resolvingItemIDs.removeAll(where: {  $0.0 == primaryID && $0.1 == groupingID && $0.2 == connectionID })
    }
}
