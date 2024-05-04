//
//  Handler+Search.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 04.05.24.
//

import Foundation
import Intents
import SPBase

extension IntentHandler: INSearchForMediaIntentHandling {
    func handle(intent: INSearchForMediaIntent) async -> INSearchForMediaIntentResponse {
        guard let item = intent.mediaItems?.first, let identifier = item.identifier else {
            return .init(code: .failure, userActivity: nil)
        }
        
        var activity: NSUserActivity
        
        switch item.type {
            case .audioBook:
                activity = .init(activityType: "io.rfk.shelfplayer.audiobook")
                activity.userInfo = [
                    "audiobookId": identifier,
                ]
            case .podcastShow:
                activity = .init(activityType: "io.rfk.shelfplayer.podcast")
                activity.userInfo = [
                    "podcastId": identifier,
                ]
            case .podcastEpisode:
                activity = .init(activityType: "io.rfk.shelfplayer.episode")
                activity.userInfo = [
                    "episodeId": identifier,
                ]
                
            default:
                return .init(code: .failure, userActivity: nil)
        }
        
        activity.title = item.title
        activity.persistentIdentifier = identifier
        
        return .init(code: .continueInApp, userActivity: activity)
    }
    
    func resolveMediaItems(for intent: INSearchForMediaIntent) async -> [INSearchForMediaMediaItemResolutionResult] {
        guard AudiobookshelfClient.shared.isAuthorized else {
            return [.unsupported(forReason: .loginRequired)]
        }
        
        guard let mediaSearch = intent.mediaSearch else {
            return [.unsupported(forReason: .unsupportedMediaType)]
        }
        
        do {
            let items = try await resolveMediaItems(mediaSearch: mediaSearch)
            
            var resolved = [INSearchForMediaMediaItemResolutionResult]()
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
