//
//  IntentHandler.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.01.24.
//

import Foundation
import Defaults
import Intents
import ShelfPlayerKit
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
        
        var items = [PlayableItem]()
        
        do {
            if mediaItem.type == .audioBook {
                items = [try await MediaResolver.shared.resolve(audiobookId: identifier)]
            } else if mediaItem.type == .podcastShow {
                items = try await MediaResolver.shared.resolve(podcastId: identifier)
            } else if mediaItem.type == .podcastEpisode {
                items = [try await MediaResolver.shared.resolve(episodeId: identifier)]
            }
            
            guard !items.isEmpty else {
                throw MediaResolver.ResolveError.empty
            }
            
            let item = items.removeFirst()
            
            if intent.playbackQueueLocation == .now {
                try await AudioPlayer.shared.play(item)
            } else {
                AudioPlayer.shared.queue(item)
            }
            
            return .init(code: .success, userActivity: nil)
        } catch {
            return .init(code: .failure, userActivity: nil)
        }
    }
}
