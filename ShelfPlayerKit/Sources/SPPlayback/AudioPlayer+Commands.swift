//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import MediaPlayer
import Defaults
import SPFoundation
import SPPersistence

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
            playing.toggle()
            return .success
        }
        
        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
        commandCenter.changePlaybackRateCommand.addTarget { [unowned self] event in
            guard let changePlaybackPositionCommandEvent = event as? MPChangePlaybackRateCommandEvent else {
                return .commandFailed
            }
            
            playbackRate = .init(changePlaybackPositionCommandEvent.playbackRate)
            return .success
        }
        
        commandCenter.bookmarkCommand.addTarget { [unowned self] event in
            guard let bookmarkCommandEvent = event as? MPFeedbackCommandEvent else {
                return .commandFailed
            }
            
            guard let audiobook = item as? Audiobook else {
                return .noActionableNowPlayingItem
            }
            
            if bookmarkCommandEvent.isNegative {
                guard let bookmarks = try? OfflineManager.shared.bookmarks(itemId: audiobook.id),
                      let bookmark = bookmarks.first(where: { abs($0.position - itemCurrentTime) <= 5 }) else {
                    return .noSuchContent
                }
                
                Task {
                    try await OfflineManager.shared.deleteBookmark(bookmark)
                }
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = .autoupdatingCurrent
                dateFormatter.timeZone = .current
                
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                
                Task {
                    try await OfflineManager.shared.createBookmark(itemId: audiobook.id, position: itemCurrentTime, note: dateFormatter.string(from: .now))
                }
            }
            
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            if Defaults[.lockSeekBar] {
                return .noActionableNowPlayingItem
            }
            
            guard let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            
            chapterCurrentTime = changePlaybackPositionCommandEvent.positionTime
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipBackwardsInterval)]
        commandCenter.skipBackwardCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPSkipIntervalCommandEvent {
                itemCurrentTime = itemCurrentTime - changePlaybackPositionCommandEvent.interval
                return .success
            }
            
            return .commandFailed
        }
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: skipForwardsInterval)]
        commandCenter.skipForwardCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPSkipIntervalCommandEvent {
                itemCurrentTime = itemCurrentTime + changePlaybackPositionCommandEvent.interval
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            skipBackwards()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            skipForwards()
            return .success
        }
        
        commandCenter.seekBackwardCommand.addTarget { [unowned self] event in
            skipBackwards()
            return .success
        }
        commandCenter.seekForwardCommand.addTarget { [unowned self] event in
            skipForwards()
            return .success
        }
    }
    
    func updateBookmarkCommand(active: Bool) {
        MPRemoteCommandCenter.shared().bookmarkCommand.isEnabled = active
    }
}
