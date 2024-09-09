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
import Defaults
import SPFoundation

internal extension AudioPlayer {
    func setupObservers() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            if chapterTTL < itemCurrentTime {
                updateChapterIndex()
            }
            
            updateNowPlayingWidget()
            playbackReporter?.reportProgress(currentTime: itemCurrentTime, duration: itemDuration)
            
            if let playItem = audioPlayer.currentItem, playing {
                if playItem.isPlaybackBufferEmpty {
                    buffering = true
                } else {
                    buffering = !playItem.isPlaybackLikelyToKeepUp && !playItem.isPlaybackBufferFull
                }
            } else {
                buffering = false
            }
            
            NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
        }
        
        rateSubscription = audioPlayer.observe(\.rate) { _, _ in
            NotificationCenter.default.post(name: AudioPlayer.playingDidChangeNotification, object: nil)
        }
        volumeSubscription = AVAudioSession.sharedInstance().publisher(for: \.outputVolume).sink { volume in
            self.systemVolume = volume
            NotificationCenter.default.post(name: AudioPlayer.volumeDidChangeNotification, object: nil)
        }
        
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { _ in
            guard let currentTrackIndex = self.currentTrackIndex, currentTrackIndex + 1 < self.tracks.count else {
                if let item = self.item {
                    self.itemDidFinish(item)
                }
                
                Task {
                    try await self.advance()
                }
                
                return
            }
            
            self.currentTrackIndex? += 1
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance(), queue: nil) { notification in
            guard let userInfo = notification.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
                case .began:
                    self.playing = false
                case .ended:
                    guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    
                    if options.contains(.shouldResume) {
                        self.playing = true
                    }
                default: ()
            }
        }
        
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            self.playbackReporter = nil
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            self.checkPlayerTimeout()
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
        
        Timer.scheduledTimer(withTimeInterval: 60 * 10, repeats: true) { _ in
            self.checkPlayerTimeout()
        }
    }
    
    private func checkPlayerTimeout() {
        guard let lastPause = self.lastPause else {
            return
        }
        
        // Config values are stored in minutes, we need seconds
        let timeout: Double = Defaults[.endPlaybackTimeout] * 60 - 10
        
        guard timeout > 0 else {
            return
        }
        
        let elapsed = Date().timeIntervalSince(lastPause)
        
        if elapsed > timeout {
            self.stop()
        }
    }
}
