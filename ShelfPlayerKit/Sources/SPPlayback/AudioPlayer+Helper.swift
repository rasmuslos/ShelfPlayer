//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SPBase
import AVKit

#if canImport(SPOfflineExtended)
import SPOffline
import SPOfflineExtended
#endif

internal extension AudioPlayer {
    func getAVPlayerItem(item: PlayableItem, track: PlayableItem.AudioTrack) async -> AVPlayerItem {
        #if canImport(SPOfflineExtended)
        if let trackURL = try? await OfflineManager.shared.getTrack(itemId: item.id, track: track) {
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
