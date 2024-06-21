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
import SPExtension
import SPOfflineExtended
import SPPlayback

final internal class PlayMediaHandler: NSObject, INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        if intent.resumePlayback == true && AudioPlayer.shared.item != nil {
            AudioPlayer.shared.playing = true
            return .init(code: .success, userActivity: nil)
        }
        
        guard let mediaItem = intent.mediaItems?.first, let identifier = mediaItem.identifier else {
            return .init(code: .failure, userActivity: nil)
        }
        
        var item: PlayableItem? = nil
        
        do {
            if mediaItem.type == .audioBook {
                item = try await MediaResolver.shared.resolve(audiobookId: identifier)
            } else if mediaItem.type == .podcastShow {
                item = try await MediaResolver.shared.resolve(podcastId: identifier).first
            } else if mediaItem.type == .podcastEpisode {
                item = try await MediaResolver.shared.resolve(episodeId: identifier)
            }
            
            guard let item = item else {
                throw MediaResolver.ResolveError.empty
            }
            
            item.startPlayback()
            
            return .init(code: .success, userActivity: nil)
        } catch {
            return .init(code: .failure, userActivity: nil)
        }
    }
}
