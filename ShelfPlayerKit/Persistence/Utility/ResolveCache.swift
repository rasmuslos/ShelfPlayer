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
    
    private var cache = [ItemIdentifier: Item]()
    private var episodeCache = [ItemIdentifier: [Episode]]()
    
    func resolve(_ itemID: ItemIdentifier) async throws -> (Item, [Episode]) {
        if let cached = cache[itemID] {
            return (cached, episodeCache[itemID] ?? [])
        }
        
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
                }
            }
        } catch {
            throw ResolveError.notFound
        }
        
        cache[item.id] = item
        
        for episode in episodes {
            cache[episode.id] = episode
        }
        
        return (item, episodes)
    }
    public func resolve(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws -> PlayableItem {
        if let cached = cache.first(where: { $0.key.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }), let item = cached.value as? PlayableItem {
            return item
        }
        
        if let groupingID {
            let (podcast, episodes) = try await ABSClient[connectionID].podcast(with: .init(primaryID: groupingID, groupingID: nil, libraryID: "_", connectionID: connectionID, type: .podcast))
            
            cache[podcast.id] = podcast
            episodeCache[podcast.id] = episodes
            
            for episode in episodes {
                cache[episode.id] = episode
            }
            
            guard let episode = episodes.first(where: { $0.id.primaryID == primaryID }) else {
                throw ResolveError.notFound
            }
            
            return episode
        } else {
            let audiobook = try await ABSClient[connectionID].audiobook(primaryID: primaryID)
            
            cache[audiobook.id] = audiobook
            return audiobook
        }
    }
    
    public func invalidate() {
        cache.removeAll()
        episodeCache.removeAll()
    }
    
    private enum ResolveError: Error {
        case notFound
    }
    
    public nonisolated static let shared = ResolveCache()
}
