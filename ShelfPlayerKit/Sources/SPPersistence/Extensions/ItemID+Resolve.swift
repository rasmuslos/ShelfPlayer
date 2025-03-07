//
//  ItemID+Resolve.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.02.25.
//

import Foundation
import OSLog
import SPFoundation

public extension ItemIdentifier {
    var resolved: Item {
        get async throws {
            try await resolvedComplex.0
        }
    }
    var resolvedComplex: (Item, [Episode]) {
        get async throws {
            try await ResolveCache.shared.resolve(self)
        }
    }
}

private actor ResolveCache: Sendable {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ResolveCache")
    
    var cache: [ItemIdentifier: Item] = [:]
    var episodeCache: [ItemIdentifier: [Episode]] = [:]
    
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
                    do {
                        episodes = try await ABSClient[itemID.connectionID].episodes(from: itemID)
                    } catch {
                        episodes = try await PersistenceManager.shared.download.episodes(from: itemID)
                    }
                } else {
                    episodes = []
                }
            } else {
                switch itemID.type {
                case .audiobook, .episode:
                    item = try await ABSClient[itemID.connectionID].playableItem(itemID: itemID).0
                    episodes = []
                case .author:
                    item = try await ABSClient[itemID.connectionID].author(with: itemID)
                    episodes = []
                case .series:
                    item = try await ABSClient[itemID.connectionID].series(with: itemID)
                    episodes = []
                case .podcast:
                    (item, episodes) = try await ABSClient[itemID.connectionID].podcast(with: itemID)
                }
            }
        } catch {
            throw ResolveError.notFound
        }
        
        cache[itemID] = item
        episodeCache[itemID] = episodes
        
        for episode in episodes {
            cache[episode.id] = episode
        }
        
        return (item, episodes)
    }
    
    enum ResolveError: Error {
        case notFound
    }
    
    nonisolated static let shared = ResolveCache()
}
