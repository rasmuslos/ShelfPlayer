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
            }
        }
    }
    public var expiresAtChapterEnd: Bool {
        didSet {
            if expiresAtChapterEnd {
                expiresAt = nil
                suspend()
            }
        }
    }
    
    var isSuspended: Bool
    var timer: DispatchSourceTimer
    
    private init() {
        expiresAt = nil
        expiresAtChapterEnd = false
        
        isSuspended = true
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: AudioPlayer.shared.dispatchQueue)
        
        setupObservers()
    }
}

public extension SleepTimer {
    static let shared = SleepTimer()
}
