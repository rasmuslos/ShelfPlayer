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
                expiresAtChapterEnd = nil
                setupTimer()
                
                if let timeInterval = expiresAt?.distance(to: .now()).timeInterval {
                    let amount = min(-timeInterval, 60 * 60 * 6)
                    lastSetting = .time(interval: amount)
                }
            }
            
            NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
        }
    }
    public var expiresAtChapterEnd: Int? {
        didSet {
            if let expiresAtChapterEnd, expiresAtChapterEnd <= 0 {
                self.expiresAtChapterEnd = nil
            }
            
            if let expiresAtChapterEnd {
                expiresAt = nil
                suspend()
                
                lastSetting = .chapterEnd(amount: abs(expiresAtChapterEnd - (oldValue ?? 0)))
            }
            
            NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
        }
    }
    
    var expiredAt: Date?
    var lastSetting: SleepTimerSetting?
    
    var isSuspended: Bool
    var timer: DispatchSourceTimer
    
    private init() {
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: AudioPlayer.shared.dispatchQueue)
        timer.activate()
        
        expiresAt = nil
        expiresAtChapterEnd = nil
        
        expiredAt = nil
        lastSetting = nil
        
        isSuspended = false
        suspend()
        
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
        case .chapterEnd(let amount):
            if let expiresAtChapterEnd {
                self.expiresAtChapterEnd? += amount
            } else {
                expiresAtChapterEnd = amount
            }
        }
    }
    
    enum SleepTimerSetting {
        case time(interval: TimeInterval)
        case chapterEnd(amount: Int)
    }
}

public extension SleepTimer {
    static let shared = SleepTimer()
}
