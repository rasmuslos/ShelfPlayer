//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import AVKit
import SPFoundation
import SPNetwork

#if canImport(SPOfflineExtended)
import SPOffline
import SPOfflineExtended
#endif

internal extension AudioPlayer {
    func updateChapterIndex() {
        if !enableChapterTrack || chapters.count <= 1 {
            currentChapterIndex = nil
            return
        }
        
        currentChapterIndex = chapters.firstIndex { $0.start <= itemCurrentTime && $0.end > itemCurrentTime }
    }
}

internal extension AudioPlayer {
    func avPlayerItem(item: PlayableItem, track: PlayableItem.AudioTrack) async -> AVPlayerItem {
        #if canImport(SPOfflineExtended)
        if let trackURL = try? OfflineManager.shared.url(for: track, itemId: item.id) {
            return AVPlayerItem(url: trackURL)
        }
        #endif
        
        return AVPlayerItem(url: AudiobookshelfClient.shared.serverUrl
            .appending(path: track.contentUrl.removingPercentEncoding ?? "")
            .appending(queryItems: [
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token)
            ]))
    }
}

internal extension AudioPlayer {
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        } catch {
            logger.fault("Failed to setup audio session")
        }
    }
    
    func updateAudioSession(active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
            try AVAudioSession.sharedInstance().setSupportsMultichannelContent(true)
        } catch {
            logger.fault("Failed to update audio session")
        }
    }
}
