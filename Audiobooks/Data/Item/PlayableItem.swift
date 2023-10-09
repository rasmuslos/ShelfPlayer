//
//  PlayableItem.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation

class PlayableItem: Item {
    func getPlaybackData() async throws -> (AudioTracks, Chapters) {
        if let episode = self as? Episode {
            return try await AudiobookshelfClient.shared.play(itemId: episode.podcastId, episodeId: episode.id)
        } else {
            return try await AudiobookshelfClient.shared.play(itemId: id, episodeId: nil)
        }
    }
}

// MARK: Types

extension PlayableItem {
    struct AudioTrack {
        let index: Int
        
        let offset: Double
        let duration: Double
        
        let codec: String
        let mimeType: String
        let contentUrl: String
    }
    typealias AudioTracks = [AudioTrack]
    
    struct Chapter: Identifiable {
        let id: String
        let start: Double
        let end: Double
        let title: String
    }
    typealias Chapters = [Chapter]
}
