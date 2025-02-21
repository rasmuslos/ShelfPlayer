//
//  SleepTimer+Timer.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 11.09.24.
//

import Foundation

internal extension SleepTimer {
    func setupTimer() {
        guard let deadline else {
            return
        }
        
        timer.schedule(deadline: deadline)
        resume()
    }
    
    func suspend() {
        guard !isSuspended else {
            return
        }
        
        timer.suspend()
        isSuspended = true
    }
    func resume() {
        guard isSuspended else {
            return
        }
        
        timer.resume()
        isSuspended = false
    }
}

private extension SleepTimer {
    var deadline: DispatchTime? {
        guard let expiresAt else {
            return nil
        }
        
        let delta = DispatchTime.now().distance(to: expiresAt)
        
        guard let timeInterval = delta.seconds else {
            return nil
        }
        
        if timeInterval <= 0.5 {
            didExpire()
            return nil
        }
        
        if timeInterval <= 10 {
            return .now().advanced(by: .seconds(1))
        }
        
        return expiresAt.advanced(by: .seconds(-10))
    }
}
