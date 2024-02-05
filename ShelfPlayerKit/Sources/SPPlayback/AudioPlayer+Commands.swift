//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import MediaPlayer

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
    }
}
