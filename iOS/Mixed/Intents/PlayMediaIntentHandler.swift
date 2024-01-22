//
//  IntentHandler.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.01.24.
//

import Foundation
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
            break
        case .podcastEpisode:
            break
        default:
            return .init(code: .failure, userActivity: nil)
        }
        
        return .init(code: .success, userActivity: nil)
    }
    
    func resolveMediaItems(for intent: INPlayMediaIntent) async -> [INPlayMediaMediaItemResolutionResult] {
        if !AudiobookshelfClient.shared.isAuthorized { return [.unsupported(forReason: .loginRequired)] }
        guard let search = intent.mediaSearch else { return [.unsupported(forReason: .serviceUnavailable)] }
        
        var result = [Item]()
        
        result += await resolveAudiobooks(name: search.mediaName ?? "")
        
        if !result.isEmpty {
            return INPlayMediaMediaItemResolutionResult.successes(with: mapMediaItems(result))
        }
        
        return [.unsupported()]
    }
}

extension PlayMediaIntentHandler {
    func resolveAudiobooks(name: String) async -> [Audiobook] {
        var audiobooks = [Audiobook]()
        
        if let offline = try? await OfflineManager.shared.getAudiobooks(query: name) {
            audiobooks += offline
        }
        
        try? await AudiobookshelfClient.shared.getLibraries().filter { $0.type == .audiobooks }.parallelMap {
            print(name)
            return try await AudiobookshelfClient.shared.getItems(query: name, libraryId: $0.id)
        }.forEach { audiobooks.append(contentsOf: $0.0) }
        
        return audiobooks
    }
    
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
}
