//
//  IntentHandler.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.01.24.
//

import Foundation
import Defaults
import Intents
import SPBase
import SPOffline
import SPOfflineExtended
import SPPlayback

class PlayMediaIntentHandler: NSObject, INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        guard let item = intent.mediaItems?.first, let identifier = item.identifier else { return .init(code: .failure, userActivity: nil) }
        
        switch item.type {
            case .audioBook:
                if let audiobook = try? await OfflineManager.shared.getAudiobook(audiobookId: identifier) {
                    audiobook.startPlayback()
                    break
                } else if let response = try? await AudiobookshelfClient.shared.getItem(itemId: identifier, episodeId: nil), let audiobook = response.0 as? Audiobook {
                    audiobook.startPlayback()
                    break
                }
                
                return .init(code: .failure, userActivity: nil)
            case .podcastShow:
                if let podcast = try? await OfflineManager.shared.getPodcast(podcastId: identifier) {
                    if let episodes = try? await OfflineManager.shared.getEpisodes(podcastId: podcast.id) {
                        let sorted = await EpisodeSortFilter.filterSort(
                            episodes: episodes,
                            filter: Defaults[.episodesFilter(podcastId: podcast.id)],
                            sortOrder: Defaults[.episodesSort(podcastId: podcast.id)],
                            ascending: Defaults[.episodesAscending(podcastId: podcast.id)])
                        
                        // Prefer in progress episodes
                        for episode in sorted {
                            let entity = await OfflineManager.shared.requireProgressEntity(item: episode)
                            
                            if entity.progress > 0 {
                                episode.startPlayback()
                                break
                            }
                        }
                        
                        if let episode = sorted.first {
                            episode.startPlayback()
                            break
                        }
                    }
                }
                
                if let response = try? await AudiobookshelfClient.shared.getPodcast(podcastId: identifier) {
                    let sorted = await EpisodeSortFilter.filterSort(
                        episodes: response.1,
                        filter: Defaults[.episodesFilter(podcastId: response.0.id)],
                        sortOrder: Defaults[.episodesSort(podcastId: response.0.id)],
                        ascending: Defaults[.episodesAscending(podcastId: response.0.id)])
                    
                    if let episode = sorted.first {
                        episode.startPlayback()
                        break
                    }
                }
                
                return .init(code: .failure, userActivity: nil)
            case .podcastEpisode:
                if let episode = try? await OfflineManager.shared.getEpisode(episodeId: identifier) {
                    episode.startPlayback()
                    break
                }
                
                return .init(code: .failure, userActivity: nil)
            default:
                return .init(code: .failure, userActivity: nil)
        }
        
        return .init(code: .success, userActivity: nil)
    }
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        if !AudiobookshelfClient.shared.isAuthorized { return [.unsupported(forReason: .loginRequired)] }
        guard let search = intent.mediaSearch, let mediaName = search.mediaName else { return [.unsupported(forReason: .serviceUnavailable)] }
        
        var result = [Item]()
        
        result += await resolveAudiobooks(name: mediaName)
        result += await resolvePodcasts(name: mediaName)
        result += await resolveEpisodes(name: mediaName)
        
        if !result.isEmpty {
            result.sort {
                $0.name.levenshteinDistanceScore(to: mediaName) < $1.name.levenshteinDistanceScore(to: mediaName)
            }
            
            return INPlayMediaMediaItemResolutionResult.successes(with: mapMediaItems(result))
        }
        
        return []
    }
}

extension PlayMediaIntentHandler {
    func resolveAudiobooks(name: String) async -> [Audiobook] {
        var audiobooks = [Audiobook]()
        
        do {
            if let offline = try? await OfflineManager.shared.getAudiobooks(query: name) {
                audiobooks += offline
            }
            
            if Defaults[.siriOfflineMode] {
                throw PlayMediaError.offlineMode
            }
            
            try await AudiobookshelfClient.shared.getLibraries().filter { $0.type == .audiobooks }.parallelMap {
                try await AudiobookshelfClient.shared.getItems(query: name, libraryId: $0.id)
            }.forEach { audiobooks.append(contentsOf: $0.0) }
        } catch {}
        
        var seenIds = Set<String>()
        return audiobooks.filter {
            if seenIds.contains($0.id) {
                return false
            }
            
            seenIds.insert($0.id)
            return true
        }
    }
    
    func resolvePodcasts(name: String) async -> [Podcast] {
        var podcasts = [Podcast]()
        
        do {
            if let offline = try? await OfflineManager.shared.getPodcasts(query: name) {
                podcasts += offline
            }
            
            if Defaults[.siriOfflineMode] {
                throw PlayMediaError.offlineMode
            }
            
            try await AudiobookshelfClient.shared.getLibraries().filter { $0.type == .podcasts }.parallelMap {
                try await AudiobookshelfClient.shared.getItems(query: name, libraryId: $0.id)
            }.forEach { podcasts.append(contentsOf: $0.1) }
        } catch {}
        
        var seenIds = Set<String>()
        return podcasts.filter {
            if seenIds.contains($0.id) {
                return false
            }
            
            seenIds.insert($0.id)
            return true
        }
    }
    
    func resolveEpisodes(name: String) async -> [Episode] {
        // the current ABS api design does not really allow this...
        return (try? await OfflineManager.shared.getEpisodes(query: name)) ?? []
    }
}

extension PlayMediaIntentHandler {
    func mapMediaItems(_ items: [Item]) -> [INMediaItem] {
        items.map { item in
            INMediaItem(
                identifier: item.id,
                title: item.name,
                type: convertType(item: item),
                artwork: convertImage(image: item.image), artist: item.author)
        }
    }
    
    func convertImage(image: Item.Image?) -> INImage? {
        guard let image = image else { return nil }
        
        
        if image.type == .local {
            return INImage(url: image.url)
        }
        
        if let data = try? Data(contentsOf: image.url) {
            return INImage(imageData: data)
        }
        
        return nil
    }
    func convertType(item: Item) -> INMediaItemType {
        switch item {
            case is Audiobook:
                return .audioBook
            case is Episode:
                return .podcastEpisode
            case is Podcast:
                return .podcastShow
            default:
                return .unknown
        }
    }
    
    enum PlayMediaError: Error {
        case offlineMode
    }
}
