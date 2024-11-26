//
//  IntentHelper.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.10.24.
//

import Foundation
import Intents
import ShelfPlayerKit
import SPPlayback

// MARK: Convert

internal struct IntentHelper {
    static func convert(item: Item) async -> INMediaItem? {
        guard let itemType = convert(type: item.type) else {
            return nil
        }
        
        let artwork: INImage?
        
        if let data = await item.cover?.data {
            artwork = INImage(imageData: data)
        } else {
            artwork = nil
        }
        
        return INMediaItem(
            identifier: convertIdentifier(item: item),
            title: item.name,
            type: itemType,
            artwork: artwork,
            artist: item.authors.joined(separator: ", "))
    }
    
    static func createIntent(item: Item) async -> INPlayMediaIntent? {
        guard let mediaItem = await convert(item: item) else {
            return nil
        }
        
        let intent = INPlayMediaIntent(
            mediaItems: [mediaItem],
            mediaContainer: nil,
            playShuffled: nil,
            playbackRepeatMode: .unknown,
            resumePlayback: true,
            playbackQueueLocation: .now,
            playbackSpeed: AudioPlayer.shared.playbackRate,
            mediaSearch: nil)
        
        return intent
    }
    
    private static func convert(type: Item.ItemType) -> INMediaItemType? {
        switch type {
        case .audiobook:
                .audioBook
        case .author:
                .artist
        case .podcast:
                .podcastShow
        case .episode:
                .podcastEpisode
        default:
            nil
        }
    }
}

// MARK: Resolve Utility

private extension IntentHelper {
    static func finalize<R: INMediaItemResolutionResult>(items: [Item], search: String) async -> [R] {
        let ranked = items.map { ($0.name.levenshteinDistanceScore(to: search), $0) }.sorted { $0.0 > $1.0 }
        let grouped = Dictionary(grouping: ranked, by: \.0)
        
        UserContext.logger.info("Resolved \(ranked.map { ($0, $1.name) }) for \"\(search)\"")
        
        var result = [R]()
        
        for group in grouped {
            if group.value.count == 1 {
                guard let intentItem = await convert(item: group.value.first!.1) else {
                    continue
                }
                
                result.append(.success(with: intentItem))
            } else {
                let intentsItems = await convert(items: group.value.map(\.1))
                result.append(.disambiguation(with: intentsItems))
            }
        }
        
        return result
    }
    static func convert(items: [Item]) async -> [INMediaItem] {
        var result = [INMediaItem]()
        
        for item in items {
            guard let intentItem = await convert(item: item) else { continue }
            result.append(intentItem)
        }
        
        return result
    }
}

// MARK: Resolve Online

internal extension IntentHelper {
    static func resolveOnline<R: INMediaItemResolutionResult>(mediaSearch: INMediaSearch) async throws -> [R] {
        // MARK: Identifier provided
        
        if let identifier = mediaSearch.mediaIdentifier {
            let (itemID, episodeID, _, itemType) = convertIdentifier(identifier: identifier)
            
            let item: Item
            
            switch itemType {
            case .audiobook, .episode:
                item = try await AudiobookshelfClient.shared.item(itemId: itemID, episodeId: episodeID).0
            case .author:
                item = try await AudiobookshelfClient.shared.author(authorId: itemID)
            case .series:
                return [.unsupported()]
            case .podcast:
                item = try await AudiobookshelfClient.shared.podcast(podcastId: itemID).0
            }
            
            guard let mediaItem = await convert(item: item) else {
                return [.unsupported()]
            }
            
            return [.success(with: mediaItem)]
        }
        
        // MARK: Search using provided searches
        
        let search = mediaSearch.mediaName ?? mediaSearch.artistName ?? ""
        
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let libraries = try await AudiobookshelfClient.shared.libraries()
        
        var items: [Item] = []
        
        switch mediaSearch.mediaType {
        case .audioBook:
            items += try await searchForAudiobooks(search, libraries: libraries)
        case .podcastShow:
            items += try await searchForPodcasts(search, libraries: libraries)
        default:
            items += try await Self.search(search, libraries: libraries)
        }
        
        return await finalize(items: items, search: search)
    }
    
    static func searchForAudiobooks(_ search: String, libraries: [Library]) async throws -> [Audiobook] {
        var result = [Audiobook]()
        
        for library in libraries.filter({ $0.type == .audiobooks }) {
            result += try await AudiobookshelfClient.shared.items(search: search, libraryID: library.id).0
        }
        
        return result
    }
    
    static func searchForPodcasts(_ search: String, libraries: [Library]) async throws -> [Podcast] {
        var result = [Podcast]()
        
        for library in libraries.filter({ $0.type == .podcasts }) {
            result += try await AudiobookshelfClient.shared.items(search: search, libraryID: library.id).1
        }
        
        return result
    }
    
    static func search(_ search: String, libraries: [Library]) async throws -> [Item] {
        var result = [Item]()
        
        for library in libraries {
            result += try await AudiobookshelfClient.shared.items(search: search, libraryID: library.id).0
            result += try await AudiobookshelfClient.shared.items(search: search, libraryID: library.id).1
            result += try await AudiobookshelfClient.shared.items(search: search, libraryID: library.id).2
        }
        
        return result
    }
}

// MARK: Resolve Offline

internal extension IntentHelper {
    static func resolveOffline<R: INMediaItemResolutionResult>(mediaSearch: INMediaSearch) async throws -> [R] {
        // MARK: Identifier provided
        
        if let identifier = mediaSearch.mediaIdentifier {
            let (itemID, episodeID, _, itemType) = convertIdentifier(identifier: identifier)
            
            let item: Item
            
            switch itemType {
            case .audiobook:
                item = try OfflineManager.shared.audiobook(audiobookId: itemID)
            case .podcast:
                item = try OfflineManager.shared.podcast(podcastId: itemID)
            case .episode:
                guard let episodeID else {
                    return [.unsupported()]
                }
                
                item = try OfflineManager.shared.episode(episodeId: episodeID)
            default:
                return [.unsupported()]
            }
            
            guard let mediaItem = await convert(item: item) else {
                return [.unsupported()]
            }
            
            return [.success(with: mediaItem)]
        }
        
        // MARK: Search using provided searches
        
        let search = mediaSearch.mediaName ?? mediaSearch.artistName ?? ""
        
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        var items: [Item] = []
        
        switch mediaSearch.mediaType {
        case .audioBook:
            items += try OfflineManager.shared.audiobooks(query: search)
        case .podcastShow:
            items += try OfflineManager.shared.podcasts(query: search)
        case .podcastEpisode:
            items += try OfflineManager.shared.episodes(query: search)
        default:
            items += try OfflineManager.shared.audiobooks(query: search)
            items += try OfflineManager.shared.podcasts(query: search)
            items += try OfflineManager.shared.episodes(query: search)
        }
        
        return await finalize(items: items, search: search)
    }
}

// MARK: Next Up

internal extension IntentHelper {
    static func nextUp<R: INMediaItemResolutionResult>() async throws -> [R] {
        [.disambiguation(with: await convert(items: try await IntentHelper.nextUp()))]
    }
    
    static func nextUp() async throws -> [Item] {
        var items: [Item] = []
        
        for library in try await AudiobookshelfClient.shared.libraries() {
            switch library.type {
            case .audiobooks:
                let home: ([HomeRow<Audiobook>], [HomeRow<Author>]) = try await AudiobookshelfClient.shared.home(libraryID: library.id)
                if let audiobooks = home.0.filter({ $0.id == "continue-listening" }).first?.entities {
                    items += audiobooks
                }
            case .podcasts:
                let home: ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await AudiobookshelfClient.shared.home(libraryID: library.id)
                if let episodes = home.1.filter({ $0.id == "continue-listening" }).first?.entities {
                    items += episodes
                }
            default:
                break
            }
        }
        
        return items
    }
}
