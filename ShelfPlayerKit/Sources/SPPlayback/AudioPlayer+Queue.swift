//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SPFoundation

internal extension AudioPlayer {
    func getQueue(currentTime: Double) -> [PlayableItem.AudioTrack] {
        tracks.filter { $0.offset > currentTime }
    }
    func getHistory(currentTime: Double) -> [PlayableItem.AudioTrack] {
        tracks.filter { $0.offset + $0.duration < currentTime }
    }
    
    func getHistory() -> [PlayableItem.AudioTrack] {
        if let activeAudioTrackIndex = activeAudioTrackIndex {
            return Array(tracks.prefix(activeAudioTrackIndex))
        } else {
            return []
        }
    }
    
    func getTrack(currentTime: Double) -> PlayableItem.AudioTrack? {
        tracks.first { $0.offset <= currentTime && $0.offset + $0.duration > currentTime }
    }
    func getTrackIndex(currentTime: Double) -> Int? {
        tracks.firstIndex { $0.offset <= currentTime && $0.offset + $0.duration > currentTime }
    }
}
