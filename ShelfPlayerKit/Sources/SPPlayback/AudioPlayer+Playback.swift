//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import Defaults
import SPBase
import AVKit

extension AudioPlayer {
    func startPlayback(item: PlayableItem, tracks: PlayableItem.AudioTracks, chapters: PlayableItem.Chapters, startTime: Double, playbackReporter: PlaybackReporter) {
        if tracks.isEmpty {
            return
        }
        
        stopPlayback()
        
        self.item = item
        self.tracks = tracks.sorted()
        self.chapters = chapters.sorted()
        self.playbackReporter = playbackReporter
        
        Task { @MainActor in
            await seek(to: startTime)
            setPlaying(true)
            
            updateChapterIndex()
            setupNowPlayingMetadata()
        }
    }
    
    // The following functions are invoked using the computed variables
    
    func setPlaying(_ playing: Bool) {
        updateNowPlayingStatus()
        
        if playing {
            Task {
                if let lastPause = lastPause, lastPause.timeIntervalSince(Date()) >= 10 * 60 {
                    await seek(to: getItemCurrentTime() - 30)
                }
                
                lastPause = nil
                audioPlayer.play()
                updateAudioSession(active: true)
            }
        } else {
            audioPlayer.pause()
            
            if Defaults[.smartRewind] {
                lastPause = Date()
            }
        }
        
        _playing = playing
        playbackReporter?.reportProgress(playing: playing, currentTime: getItemCurrentTime(), duration: getItemDuration())
    }
    
    func setPlaybackRate(_ playbackRate: Float) {
        _playbackRate = playbackRate
        audioPlayer.defaultRate = playbackRate
        
        if playing {
            audioPlayer.rate = playbackRate
        }
    }
}
 
public extension AudioPlayer {
    func stopPlayback() {
        item = nil
        tracks = []
        chapters = []
        
        playbackReporter = nil
        
        activeAudioTrackIndex = nil
        activeChapterIndex = nil
        
        audioPlayer.removeAllItems()
        
        updateAudioSession(active: false)
        clearNowPlayingMetadata()
    }
    
    func seek(to: Double, includeChapterOffset: Bool = false) async {
        if to < 0 {
            await seek(to: 0, includeChapterOffset: includeChapterOffset)
            return
        }
        
        var to = to
        if includeChapterOffset {
            to += AudioPlayer.shared.getChapter()?.start ?? 0
        }
        
        if let index = getTrackIndex(currentTime: to) {
            if index == activeAudioTrackIndex {
                let offset = getTrack(currentTime: to)!.offset
                await audioPlayer.seek(to: CMTime(seconds: to - offset, preferredTimescale: 1000))
            } else {
                guard let item = item else { return }
                
                let resume = playing
                
                let track = getTrack(currentTime: to)!
                let queue = getQueue(currentTime: to)
                
                audioPlayer.pause()
                audioPlayer.removeAllItems()
                
                audioPlayer.insert(await getAVPlayerItem(item: item, track: track), after: nil)
                for queueTrack in queue {
                    audioPlayer.insert(await getAVPlayerItem(item: item, track: queueTrack), after: nil)
                }
                
                await audioPlayer.seek(to: CMTime(seconds: to - track.offset, preferredTimescale: 1000))
                
                activeAudioTrackIndex = index
                setPlaying(resume)
            }
        } else if to >= getItemDuration() {
            playbackReporter?.reportProgress(currentTime: getItemDuration(), duration: getItemDuration())
            stopPlayback()
        } else {
            logger.fault("Seek to position outside of range")
        }
        
        updateChapterIndex()
        updateNowPlayingStatus()
    }
    func seek(to: Double, includeChapterOffset: Bool = false) {
        Task {
            await seek(to: to, includeChapterOffset: includeChapterOffset)
        }
    }
}
