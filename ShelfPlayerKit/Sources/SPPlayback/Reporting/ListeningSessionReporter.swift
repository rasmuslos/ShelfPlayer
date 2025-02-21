//
//  OnlineSessionReporter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 21.02.25.
//

import Foundation
import SPFoundation

final actor ListeningSessionReporter: SessionReporter {
    let item: PlayableItem
    let sessionID: String
    
    var accumulatedTimeListening: TimeInterval = 0
    var startedPlayingAt: Date?
    
    init(item: PlayableItem, sessionID: String) {
        self.item = item
        self.sessionID = sessionID
    }
    
    func reportPlay() async {
        startedPlayingAt = .now
    }
    
    func reportPause() async {
        accumulatedTimeListening += timeSpendListening
    }
    
    func notify(duration: TimeInterval, currentTime: TimeInterval) async {
        
    }
}

private extension ListeningSessionReporter {
    var timeSpendListening: TimeInterval {
        let amount: TimeInterval
        
        if let startedPlayingAt {
            amount = Date.now.timeIntervalSince(startedPlayingAt)
        } else {
            amount = 0
        }
        
        startedPlayingAt = nil
        return amount
    }
}
