//
//  PlayMediaIntentHandler.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.10.24.
//

import Foundation
@preconcurrency import Intents
import OSLog
import ShelfPlayback

final class PlayMediaIntentHandler: NSObject, INPlayMediaIntentHandling {
    let logger = Logger(subsystem: "Intents", category: "PlayMedia")
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        if let items = intent.mediaItems {
            return INPlayMediaMediaItemResolutionResult.successes(with: items)
        }
        
        guard let search = intent.mediaSearch, let query = search.mediaName ?? search.artistName ?? search.albumName ?? search.genreNames?.first else {
            return await INPlayMediaMediaItemResolutionResult.successes(with: listenNowIntentItems())
        }
        
        let includeOnlineResults = search.reference != .my
        
        do {
            let items = try await ShelfPlayerKit.globalSearch(query: query, includeOnlineSearchResults: includeOnlineResults)
            
            return await INPlayMediaMediaItemResolutionResult.successes(with: convertSortedArray(items))
        } catch {
            return [INPlayMediaMediaItemResolutionResult.unsupported(forReason: .serviceUnavailable)]
        }
    }
    
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent) async -> INPlaybackQueueLocationResolutionResult {
        if intent.playbackQueueLocation == .next || intent.playbackQueueLocation == .later {
            .success(with: .later)
        } else {
            .success(with: .now)
        }
    }
    
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        guard let identifier = intent.mediaItems?.first?.identifier, ItemIdentifier.isValid(identifier) else {
            return .init(code: .failure, userActivity: nil)
        }
        
        let itemID = ItemIdentifier(identifier)
        let shouldQueue = intent.playbackQueueLocation == .later
        let startWithoutListeningSession = intent.mediaSearch?.reference == .my
        
        do {
            switch itemID.type {
                case .audiobook, .episode:
                    if shouldQueue {
                        try await AudioPlayer.shared.queue([.init(itemID: itemID, origin: .unknown, startWithoutListeningSession: startWithoutListeningSession)])
                    } else {
                        try await AudioPlayer.shared.start(.init(itemID: itemID, origin: .unknown, startWithoutListeningSession: startWithoutListeningSession))
                    }
                case .series, .podcast:
                    if shouldQueue {
                        try await AudioPlayer.shared.queueGrouping(itemID, startWithoutListeningSession: startWithoutListeningSession)
                    } else {
                        try await AudioPlayer.shared.startGrouping(itemID, startWithoutListeningSession: startWithoutListeningSession)
                    }
                default:
                    return .init(code: .failureUnknownMediaType, userActivity: nil)
            }
        } catch {
            return .init(code: .failure, userActivity: nil)
        }
        
        return .init(code: .success, userActivity: nil)
    }
    
    static func buildPlayMediaIntent(_ item: PlayableItem, container: INMediaItem? = nil) async throws -> INPlayMediaIntent {
        let intentItem = try await buildIntentItem(item)
        return INPlayMediaIntent(mediaItems: [intentItem], mediaContainer: container, playShuffled: nil, playbackRepeatMode: .unknown, resumePlayback: nil, playbackQueueLocation: .now, playbackSpeed: await AudioPlayer.shared.playbackRate, mediaSearch: nil)
    }
    static func donateListenNowIntents() async {
        INUpcomingMediaManager.shared.setPredictionMode(.default, for: .audioBook)
        INUpcomingMediaManager.shared.setPredictionMode(.default, for: .podcastShow)
        
        INUpcomingMediaManager.shared.setPredictionMode(.onlyPredictSuggestedIntents, for: .podcastEpisode)
        
        var intents = [INPlayMediaIntent]()
        
        for item in await ShelfPlayerKit.listenNowItems {
            do {
                try await intents.append(buildPlayMediaIntent(item))
                
                if let episode = item as? Episode {
                    let podcastID = episode.podcastID
                    let (podcast, episodes) = try await podcastID.resolvedComplex
                    
                    var episodeMediaItems = [INMediaItem]()
                    
                    for episode in episodes {
                        do {
                            episodeMediaItems.append(try await buildIntentItem(episode))
                        } catch {
                            continue
                        }
                    }
                    
                    try await intents.append(INPlayMediaIntent(mediaItems: episodeMediaItems, mediaContainer: buildIntentItem(podcast), playShuffled: nil, playbackRepeatMode: .unknown, resumePlayback: nil, playbackQueueLocation: .now, playbackSpeed: await AudioPlayer.shared.playbackRate, mediaSearch: nil))
                }
            } catch {
                continue
            }
        }
        
        INUpcomingMediaManager.shared.setSuggestedMediaIntents(NSOrderedSet(array: intents))
    }
    
    private static func buildIntentItem(_ item: Item) async throws -> INMediaItem {
        let type: INMediaItemType
        let image: INImage?
        
        switch item.id.type {
            case .audiobook:
                type = .audioBook
            case .episode:
                type = .podcastEpisode
            case .podcast:
                type = .podcastShow
            case .series:
                type = .station
            default:
                throw IntentError.invalidItemType
        }
        
        if let data = await item.id.data(size: .regular) {
            image = .init(imageData: data)
        } else {
            image = nil
        }
        
        return INMediaItem(identifier: item.id.description, title: item.name, type: type, artwork: image, artist: item.authors.formatted(.list(type: .and)))
    }
    private func convertSortedArray(_ items: [Item]) async -> [INMediaItem] {
        await withTaskGroup {
            for (index, item) in items.enumerated() {
                $0.addTask {
                    (index, try? await Self.buildIntentItem(item))
                }
            }
            
            return await $0.reduce(into: []) {
                $0.append($1)
            }
        }.sorted { $0.0 < $1.0 }.compactMap { $0.1 }
    }
    
    private func listenNowIntentItems() async -> [INMediaItem] {
        await convertSortedArray(ShelfPlayerKit.listenNowItems)
    }
    
    private enum IntentError: Error {
        case invalidItemType
    }
}
