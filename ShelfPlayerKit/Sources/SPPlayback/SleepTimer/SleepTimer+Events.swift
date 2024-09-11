//
//  SleepTimer+Events.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 11.09.24.
//

import Foundation

internal extension SleepTimer {
    func didPlay(pausedFor: TimeInterval) {
        expiresAt = expiresAt?.advanced(by: .milliseconds(Int(pausedFor * 1000)))
        setupTimer()
    }
    
    func didPause() {
        suspend()
    }
    
    func didExpire() {
        expiresAt = nil
        expiresAtChapterEnd = false
        
        AudioPlayer.shared.playing = false
        AudioPlayer.shared.audioPlayer.volume = 1
    }
    
    func setupObservers() {
        timer.setEventHandler { [weak self] in
            guard let self else {
                return
            }
            
            if let volume {
                AudioPlayer.shared.audioPlayer.volume = volume
            }
            
            setupTimer()
        }
        timer.activate()
        
        NotificationCenter.default.addObserver(forName: AudioPlayer.chapterDidChangeNotification, object: nil, queue: nil) { [unowned self] _ in
            if expiresAtChapterEnd {
                didExpire()
            }
        }
    }
}

private extension SleepTimer {
    var volume: Float? {
        guard let expiresAt else {
            return nil
        }
        
        let delta = DispatchTime.now().distance(to: expiresAt)
        
        guard let timeInterval = delta.timeInterval, timeInterval <= 10 else {
            return nil
        }
        
        return Float(timeInterval / 10)
    }
}
