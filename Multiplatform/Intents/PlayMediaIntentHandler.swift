//
//  PlayMediaIntentHandler.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.10.24.
//

import Foundation
import Intents
import Defaults
import ShelfPlayerKit
import SPPlayback

internal final class PlayMediaIntentHandler: NSObject, INPlayMediaIntentHandling {
}

// MARK: Resolve parameters

internal extension PlayMediaIntentHandler {
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        guard AudiobookshelfClient.shared.authorized else {
            return [.unsupported(forReason: .loginRequired)]
        }
        
        if let items = intent.mediaItems {
            return INPlayMediaMediaItemResolutionResult.successes(with: items)
        }
        
        guard let search = intent.mediaSearch else {
            do {
                return try await IntentHelper.nextUp()
            } catch {
                return [.unsupported(forReason: .serviceUnavailable)]
            }
        }
        
        // MARK: Resolve offline (optional)
        
        guard search.reference != .my else {
            UserContext.logger.info("Resolving intent offline")
            
            do {
                return try await IntentHelper.resolveOffline(mediaSearch: search)
            } catch {
                return [.unsupported(forReason: .serviceUnavailable)]
            }
        }
        
        // MARK: Resolve items
        
        let result: [INPlayMediaMediaItemResolutionResult]
        
        do {
            result = try await IntentHelper.resolveOnline(mediaSearch: search)
        } catch {
            do {
                result = try await IntentHelper.resolveOffline(mediaSearch: search)
            } catch {
                return [.unsupported(forReason: .serviceUnavailable)]
            }
        }
        
        // MARK: Suggest next up items if no matches could be found
        
        if result.isEmpty {
            do {
                if let offlineResult: [INPlayMediaMediaItemResolutionResult] = try? await IntentHelper.resolveOffline(mediaSearch: search), !offlineResult.isEmpty {
                    return offlineResult
                }
                
                return try await IntentHelper.nextUp()
            } catch {
                return [.unsupported(forReason: .serviceUnavailable)]
            }
        }
        
        return result
    }
    
    func resolvePlayShuffled(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult {
        if intent.playShuffled == true {
            return .unsupported()
        }
        
        return .success(with: false)
    }
    
    func resolveResumePlayback(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult {
        .success(with: true)
    }
    
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent) async -> INPlaybackRepeatModeResolutionResult {
        if intent.playbackRepeatMode == .none || intent.playbackRepeatMode == .unknown {
            return .success(with: .none)
        }
        
        return .unsupported()
    }
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent) async -> INPlaybackQueueLocationResolutionResult {
        if intent.playbackQueueLocation == .now || intent.playbackQueueLocation == .later {
            return .success(with: intent.playbackQueueLocation)
        }
        
        return .unsupported()
    }
}

// MARK: Handleer

internal extension PlayMediaIntentHandler {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        guard let identifier = intent.mediaItems?.first?.identifier else {
            return .init(code: .failure, userActivity: nil)
        }
        
        // MARK: Resolve parameters
        
        let resumePlayback = intent.resumePlayback ?? true
        let queueLocation = intent.playbackQueueLocation
        let offline = intent.mediaSearch?.reference == .my
        
        let (itemID, episodeID, _, itemType) = convertIdentifier(identifier: identifier)
        
        // MARK: Resolve item
        
        let item: PlayableItem?
        
        if offline {
            switch itemType {
            case .audiobook:
                item = try? OfflineManager.shared.audiobook(audiobookId: itemID)
            case .podcast:
                do {
                    let episodes = Episode.filterSort(episodes: try OfflineManager.shared.episodes(podcastId: itemID),
                                                      filter: Defaults[.episodesFilter(podcastId: itemID)],
                                                      sortOrder: Defaults[.episodesSortOrder(podcastId: itemID)],
                                                      ascending: Defaults[.episodesAscending(podcastId: itemID)])
                    
                    item = episodes.first
                } catch {
                    return .init(code: .failure, userActivity: nil)
                }
                
            case .episode:
                guard let episodeID else {
                    item = nil
                    break
                }
                
                item = try? OfflineManager.shared.episode(episodeId: episodeID)
            default:
                item = nil
            }
        } else {
            switch itemType {
            case .audiobook, .episode:
                item = try? await AudiobookshelfClient.shared.item(itemId: itemID, episodeId: episodeID).0
            default:
                item = nil
            }
        }
        
        guard let item else {
            return .init(code: .failure, userActivity: nil)
        }
        
        // MARK: Start playback
        
        if queueLocation == .later {
            AudioPlayer.shared.queue(item)
        } else {
            do {
                IntentDonator.shared.lastDonatedItem = item
                try await AudioPlayer.shared.play(item, at: resumePlayback ? nil : 0, withoutPlaybackSession: offline)
            } catch {
                return .init(code: .failure, userActivity: nil)
            }
        }
        
        return .init(code: .success, userActivity: nil)
    }
}
