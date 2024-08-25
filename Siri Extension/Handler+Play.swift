//
//  Handler+Play.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 01.05.24.
//

import Foundation
import Intents
import SPFoundation
import SPNetwork

extension IntentHandler: INPlayMediaIntentHandling {
    func handle(intent: INPlayMediaIntent) async -> INPlayMediaIntentResponse {
        .init(code: .handleInApp, userActivity: nil)
    }
    
    func resolvePlayShuffled(for intent: INPlayMediaIntent) async -> INBooleanResolutionResult {
        return .success(with: false)
    }
    func resolvePlaybackRepeatMode(for intent: INPlayMediaIntent) async -> INPlaybackRepeatModeResolutionResult {
        return .success(with: .none)
    }
    func resolvePlaybackQueueLocation(for intent: INPlayMediaIntent) async -> INPlaybackQueueLocationResolutionResult {
        return .success(with: .now)
    }
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        guard AudiobookshelfClient.shared.authorized else {
            return [.unsupported(forReason: .loginRequired)]
        }
        
        if let mediaItems = intent.mediaItems, !mediaItems.isEmpty {
            return INPlayMediaMediaItemResolutionResult.successes(with: mediaItems)
        }
        
        guard let mediaSearch = intent.mediaSearch else {
            if intent.resumePlayback == true {
                return []
            }
            
            return [.unsupported(forReason: .unsupportedMediaType)]
        }
        
        do {
            let items = try await resolveMediaItems(mediaSearch: mediaSearch)
            
            var resolved = [INPlayMediaMediaItemResolutionResult]()
            for item in items {
                resolved.append(.init(mediaItemResolutionResult: .success(with: item)))
            }
            
            return resolved
        } catch {
            if let error = error as? SearchError {
                switch error {
                    case .unavailable:
                        return [.unsupported(forReason: .serviceUnavailable)]
                    case .unsupportedMediaType:
                        return [.unsupported(forReason: .unsupportedMediaType)]
                }
            }
            
            return [.unsupported(forReason: .serviceUnavailable)]
        }
    }
}
