//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SPFoundation

internal extension AudioPlayer {
    func getQueue(currentTime: Double) -> PlayableItem.AudioTracks {
        tracks.filter { $0.offset > currentTime }
    }
    func getHistory(currentTime: Double) -> PlayableItem.AudioTracks {
        tracks.filter { $0.offset + $0.duration < currentTime }
    }
    
    func getHistory() -> PlayableItem.AudioTracks {
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

public extension AudioPlayer {
    func getItemCurrentTime() -> Double {
        var seconds: Double
        
        if tracks.count == 0 {
            seconds = audioPlayer.currentTime().seconds
        } else {
            let cacheKey = "currentTimeOffset.\(item?.id ?? "unknown").\(activeAudioTrackIndex ?? -1)"
            
            if let cached = cache[cacheKey] {
                seconds = cached
            } else {
                let history = getHistory()
                let offset = history.reduce(0, { $0 + $1.duration })
                
                cache[cacheKey] = offset
                seconds = offset
            }
            
            seconds += audioPlayer.currentTime().seconds
        }
        
        return seconds.isFinite ? seconds : 0
    }
    
    func getItemDuration() -> Double {
        let seconds: Double
        
        if tracks.count == 1 {
            seconds = audioPlayer.currentItem?.duration.seconds ?? 0
        } else {
            let cacheKey = "duration.\(item?.id ?? "unknown").\(activeAudioTrackIndex ?? -1)"
            
            if let cached = cache[cacheKey] {
                seconds = cached
            } else {
                seconds = tracks.reduce(0, { $0 + $1.duration })
                cache[cacheKey] = seconds
            }
        }
        
        return seconds.isFinite ? seconds : 0
    }
}
