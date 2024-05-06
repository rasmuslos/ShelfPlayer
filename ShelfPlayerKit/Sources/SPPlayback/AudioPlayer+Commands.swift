//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import Defaults
import MediaPlayer
import SPBase
import SPOffline

internal extension AudioPlayer {
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        } catch {
            logger.fault("Failed to setup audio session")
        }
    }
    
    func updateAudioSession(active: Bool) {
        if active {
            setupAudioSession()
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            logger.fault("Failed to update audio session")
        }
    }
}

internal extension AudioPlayer {
    func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            playing = true
            return .success
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            playing = false
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [unowned self] event in
            playing = !playing
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            if Defaults[.lockSeekBar] {
                return .noActionableNowPlayingItem
            }
            
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent {
                seek(to: changePlaybackPositionCommandEvent.positionTime, includeChapterOffset: true)
                return .success
            }
            
            return .commandFailed
        }
        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
        commandCenter.changePlaybackRateCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackRateCommandEvent {
                playbackRate = changePlaybackPositionCommandEvent.playbackRate
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.bookmarkCommand.addTarget { [unowned self] event in
            guard let bookmarkCommandEvent = event as? MPFeedbackCommandEvent else {
                return .commandFailed
            }
            
            guard let audiobook = item as? Audiobook else {
                return .noActionableNowPlayingItem
            }
            
            Task { @MainActor in
                if bookmarkCommandEvent.isNegative {
                    guard let bookmarks = try? OfflineManager.shared.getBookmarks(itemId: audiobook.id), let bookmark = bookmarks.first(where: { abs($0.position - getItemCurrentTime()) <= 5 }) else {
                        return
                    }
                    
                    await OfflineManager.shared.deleteBookmark(bookmark)
                } else {
                    await OfflineManager.shared.createBookmark(itemId: audiobook.id, position: getItemCurrentTime(), note: "Siri Bookmark")
                }
            }
            
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipBackwardsInterval)]
        commandCenter.skipBackwardCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPSkipIntervalCommandEvent {
                seek(to: getItemCurrentTime() - changePlaybackPositionCommandEvent.interval)
                return .success
            }
            
            return .commandFailed
        }
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: skipForwardsInterval)]
        commandCenter.skipForwardCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPSkipIntervalCommandEvent {
                seek(to: getItemCurrentTime() + changePlaybackPositionCommandEvent.interval)
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            seek(to: getItemCurrentTime() - Double(skipBackwardsInterval))
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            seek(to: getItemCurrentTime() + Double(skipForwardsInterval))
            return .success
        }
        
        commandCenter.seekBackwardCommand.addTarget { [unowned self] event in
            seek(to: getItemCurrentTime() - Double(skipBackwardsInterval))
            return .success
        }
        commandCenter.seekForwardCommand.addTarget { [unowned self] event in
            seek(to: getItemCurrentTime() + Double(skipForwardsInterval))
            return .success
        }
    }
    
    func updateBookmarkCommand(active: Bool) {
        MPRemoteCommandCenter.shared().bookmarkCommand.isEnabled = active
    }
}
