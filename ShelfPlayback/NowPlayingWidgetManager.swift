//
//  NowPlayingWidgetManager.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation
import OSLog
import MediaPlayer
import ShelfPlayerKit

final actor NowPlayingWidgetManager: Sendable {
    let logger = Logger(subsystem: "io.rfk.shelfPlayewrKit", category: "NowPlayingWidgetManager")
    
    var item: PlayableItem?
    var chapter: Chapter?
    
    var isPlaying: Bool?
    var isBuffering: Bool?

    var chapterDuration: TimeInterval?
    var chapterCurrentTime: TimeInterval?
    
    var metadata = [String: Any]()
    
    nonisolated func update(itemID: ItemIdentifier) {
        Task {
            do {
                guard let item = try await itemID.resolved as? PlayableItem else {
                    throw AudioPlayerError.itemMissing
                }
                
                await update(item: item)
            } catch {
                logger.error("Failed to fetch item: \(error)")
            }
        }
    }
    func update(item: PlayableItem) {
        self.item = item
        
        metadata[MPMediaItemPropertyArtist] = item.authors.formatted(.list(type: .and, width: .narrow))
        metadata[MPMediaItemPropertyReleaseDate] = item.released
        
        updateTitle()
        updateArtwork()
    }
    func update(chapter: Chapter?) {
        self.chapter = chapter
        updateTitle()
    }
    
    func update(isPlaying: Bool) {
        self.isPlaying = isPlaying
        updatePlaybackState()
    }
    func update(isBuffering: Bool) {
        self.isBuffering = isBuffering
        updatePlaybackState()
    }
    
    func update(chapterDuration: TimeInterval?) {
        self.chapterDuration = chapterDuration
        
        metadata[MPMediaItemPropertyPlaybackDuration] = chapterDuration
        updateWidget()
    }
    func update(chapterCurrentTime: TimeInterval?) {
        self.chapterCurrentTime = chapterCurrentTime
        
        metadata[MPNowPlayingInfoPropertyElapsedPlaybackTime] = chapterCurrentTime
        updateWidget()
    }
    
    func invalidate() {
        item = nil
        chapter = nil
        
        isPlaying = false
        
        chapterDuration = nil
        chapterCurrentTime = nil
        
        metadata = [:]
        
        updateWidget()
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
}

private extension NowPlayingWidgetManager {
    func updateTitle() {
        guard let item else {
            return
        }
        
        if let chapter {
            metadata[MPMediaItemPropertyTitle] = chapter.title
            metadata[MPMediaItemPropertyAlbumTitle] = item.name
        } else {
            metadata[MPMediaItemPropertyTitle] = item.name
            
            if let episode = item as? Episode {
                metadata[MPMediaItemPropertyAlbumTitle] = episode.podcastName
            } else {
                metadata[MPMediaItemPropertyAlbumTitle] = nil
            }
        }
        
        updateWidget()
    }
    nonisolated func updateArtwork() {
        Task {
            guard let item = await item else {
                await abortImageLoad()
                return
            }
            
            guard let image = await item.id.platformImage(size: .large) else {
                await abortImageLoad()
                return
            }
            
            let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ in image })
            await updateArtwork(artwork)
        }
    }
    
    func abortImageLoad() {
        metadata[MPMediaItemPropertyArtwork] = nil
        updateWidget()
    }
    func updateArtwork(_ artwork: MPMediaItemArtwork) {
        metadata[MPMediaItemPropertyArtwork] = artwork
        updateWidget()
    }
    
    func updateWidget() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = metadata
    }
    func updatePlaybackState() {
        if isBuffering == false, let isPlaying {
            MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
        } else {
            MPNowPlayingInfoCenter.default().playbackState = .interrupted
        }
    }
}
