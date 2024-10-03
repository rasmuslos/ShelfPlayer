//
//  SleepTimer.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 11.09.24.
//

import Foundation

// This is completely engineered, but pretty cool

public final class SleepTimer {
    public var expiresAt: DispatchTime? {
        didSet {
            if expiresAt == nil {
                suspend()
            } else {
                expiresAtChapterEnd = false
                setupTimer()
                
                if let timeInterval = expiresAt?.distance(to: .now()).timeInterval {
                    let amount = min(-timeInterval, 60 * 60 * 6)
                    lastSetting = .time(interval: amount)
                }
            }
            
            NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
        }
    }
    public var expiresAtChapterEnd: Bool {
        didSet {
            if expiresAtChapterEnd {
                expiresAt = nil
                suspend()
                
                lastSetting = .chapterEnd
            }
            
            NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
        }
    }
    
    var expiredAt: Date?
    var lastSetting: SleepTimerSetting?
    
    var isSuspended: Bool
    var timer: DispatchSourceTimer
    
    private init() {
        expiresAt = nil
        expiresAtChapterEnd = false
        
        expiredAt = nil
        lastSetting = nil
        
        isSuspended = true
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: AudioPlayer.shared.dispatchQueue)
        
        setupObservers()
    }
    
    public func extend() {
        guard let lastSetting else {
            return
        }
        
        switch lastSetting {
        case .time(let interval):
            if let expiresAt {
                self.expiresAt = expiresAt.advanced(by: .seconds(Int(interval)))
            } else {
                expiresAt = .now().advanced(by: .seconds(Int(interval)))
            }
        case .chapterEnd:
            expiresAtChapterEnd = true
        }
    }
    
    enum SleepTimerSetting {
        case time(interval: TimeInterval)
        case chapterEnd
    }
}

public extension SleepTimer {
    static let shared = SleepTimer()
}
