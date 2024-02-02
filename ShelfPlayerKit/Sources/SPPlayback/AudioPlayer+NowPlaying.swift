//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import MediaPlayer

internal extension AudioPlayer {
    func setupNowPlayingMetadata() {
        if let item = item {
            nowPlayingInfo = [:]
            
            nowPlayingInfo[MPMediaItemPropertyArtist] = item.author
            nowPlayingInfo[MPNowPlayingInfoPropertyChapterCount] = chapters.count
            
            updateNowPlayingTitle()
            setNowPlayingArtwork()
        }
    }
    func updateNowPlayingTitle() {
        if enableChapterTrack, chapters.count > 1 {
            nowPlayingInfo[MPMediaItemPropertyTitle] = getChapter()?.title
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = item?.name
        } else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = item?.name
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateNowPlayingStatus() {
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = playbackRate
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = getChapterDuration()
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = getChapterCurrentTime()
        nowPlayingInfo[MPNowPlayingInfoPropertyChapterNumber] = activeChapterIndex
        
        MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func clearNowPlayingMetadata() {
        nowPlayingInfo = [:]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

fileprivate extension AudioPlayer {
    #if os(iOS)
    func setNowPlayingArtwork() {
        Task.detached { [self] in
            if let imageUrl = item?.image?.url, let data = try? Data(contentsOf: imageUrl), let image = UIImage(data: data) {
                let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    #else
    func setNowPlayingArtwork() {
        // TODO: code this
    }
    #endif
}
