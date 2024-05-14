//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import Defaults
import AVKit
import UIKit
import SPBase

internal extension AudioPlayer {
    func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            let chapter = getChapter()
            if self.chapter != chapter {
                self.chapter = chapter
            }
            
            self.buffering = !(audioPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            
            self.duration = getChapterDuration()
            self.currentTime = getChapterCurrentTime()
            
            updateNowPlayingStatus()
            playbackReporter?.reportProgress(currentTime: getItemCurrentTime(), duration: getItemDuration())
            
            let currentTime = getItemCurrentTime()
            if currentTime.isFinite && !currentTime.isNaN, Int(currentTime) % 5 == 0 {
                updateChapterIndex()
            }
            
            if remainingSleepTimerTime != nil && playing {
                remainingSleepTimerTime! -= 0.5
                
                if remainingSleepTimerTime! <= 0 {
                    sleepTimerDidExpire()
                } else if remainingSleepTimerTime! <= 10 {
                    audioPlayer.volume = Float(remainingSleepTimerTime! / 10)
                }
            } else if pauseAtEndOfChapter && playing {
                let delta = getChapterDuration() - getChapterCurrentTime()
                
                if delta <= 10 {
                    audioPlayer.volume = Float(delta / 10)
                }
            }
        }
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { [weak self] _ in
            if self?.activeAudioTrackIndex == (self?.tracks.count ?? 0) - 1 {
                if let duration = self?.getItemDuration() {
                    self?.playbackReporter?.reportProgress(currentTime: duration, duration: duration)
                }
                
                Task {
                    if let (_, next) = await Self.nextEpisode() {
                        next.startPlayback()
                    }
                }
                
                self?.stopPlayback()
                return
            }
            
            self?.activeAudioTrackIndex? += 1
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance(), queue: nil) { [weak self] notification in
            guard let userInfo = notification.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
                case .began:
                    self?.setPlaying(false)
                case .ended:
                    guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    
                    if options.contains(.shouldResume) {
                        self?.setPlaying(true)
                    }
                default: ()
            }
        }
        
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.playbackReporter = nil
        }
        #endif
        
        Task {
            for await value in Defaults.updates(.skipBackwardsInterval) {
                skipBackwardsInterval = value
            }
        }
        Task {
            for await value in Defaults.updates(.skipForwardsInterval) {
                skipForwardsInterval = value
            }
        }
        Task {
            for await value in Defaults.updates(.enableChapterTrack) {
                enableChapterTrack = value
                updateChapterIndex()
            }
        }
    }
}
