//
//  AudioPlayer+Widget.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation
import MediaPlayer
import SPFoundation
import SPPersistence

internal extension AudioPlayer {
    func populateNowPlayingWidgetMetadata() async {
        guard let item else {
            return
        }
        
        var update = [String: Any]()
        
        update[MPMediaItemPropertyArtist] = item.authors.joined(separator: ", ")
        update[MPMediaItemPropertyReleaseDate] = item.released
        update[MPNowPlayingInfoPropertyChapterCount] = chapters.count
        
        await nowPlayingInfo.clear()
        await self.nowPlayingInfo.append(update)
        
        await updateNowPlayingTitle()
        await updateLastBookmarkTime()
        
        Task {
            if let image = await item.cover?.platformImage {
                let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
                await nowPlayingInfo.set(MPMediaItemPropertyArtwork, value: artwork)
                
                await updateNowPlayingInfo()
            }
        }
    }
    
    func updateNowPlayingTitle() async {
        guard let item else {
            return
        }
        
        var update = [String: Any]()
        
        if enableChapterTrack, let chapter {
            update[MPMediaItemPropertyTitle] = chapter.title
            update[MPMediaItemPropertyAlbumTitle] = item.name
        } else {
            update[MPMediaItemPropertyTitle] = item.name
            update[MPMediaItemPropertyAlbumTitle] = nil
        }
        
        await nowPlayingInfo.append(update)
        await updateNowPlayingInfo()
    }
    
    func updateLastBookmarkTime() async {
        if let audiobook = item as? Audiobook, let bookmarks = try? OfflineManager.shared.bookmarks(itemId: audiobook.id) {
            await nowPlayingInfo.set(MPMediaItemPropertyBookmarkTime, value: bookmarks.last?.position as Any)
        }
    }
    
    func updateNowPlayingWidget() async {
        var update = [String: Any]()
        
        update[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer.rate
        update[MPNowPlayingInfoPropertyDefaultPlaybackRate] = playbackRate
        
        update[MPMediaItemPropertyPlaybackDuration] = chapterDuration
        update[MPNowPlayingInfoPropertyElapsedPlaybackTime] = chapterCurrentTime
        update[MPNowPlayingInfoPropertyChapterNumber] = currentChapterIndex
        
        await nowPlayingInfo.append(update)
        await updateNowPlayingInfo()
    }
    
    func clearNowPlayingMetadata() async {
        await nowPlayingInfo.clear()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = await nowPlayingInfo.disctory
    }
    
    private func updateNowPlayingInfo() async {
        if let lastWidgetUpdate {
            guard lastWidgetUpdate.timeIntervalSinceNow < -0.2 else {
                return
            }
        }
        
        lastWidgetUpdate = .now
        
        MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = await nowPlayingInfo.disctory
    }
}
