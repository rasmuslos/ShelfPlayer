//
//  PlayableItem.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation

class PlayableItem: Item {
    func getPlaybackData() async throws -> (AudioTracks, Chapters, Double) {
        throw PlaybackError.methodNotImplemented
    }
}

// MARK: Playback

extension PlayableItem {
    func startPlayback() {
        Task {
            if let (tracks, chapters, startTime) = try? await getPlaybackData() {
                AudioPlayer.shared.startPlayback(item: self, tracks: tracks, chapters: chapters, startTime: startTime)
            }
        }
    }
}

// MARK: Errors

extension PlayableItem {
    enum PlaybackError: Error {
        case methodNotImplemented
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
        let id: Int
        let start: Double
        let end: Double
        let title: String
    }
    typealias Chapters = [Chapter]
}
