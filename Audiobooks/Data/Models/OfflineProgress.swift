//
//  OfflineSession.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData

@Model
class OfflineProgress: Identifiable {
    @Attribute(.unique) let id: String
    let itemId: String
    let additionalId: String?
    
    var duration: Double
    var currentTime: Double
    var progress: Double
    
    var startedAt: Date
    var lastUpdate: Date
    
    var progressType: ProgressType
    
    init(id: String, itemId: String, additionalId: String?, duration: Double, currentTime: Double, progress: Double, startedAt: Date, lastUpdate: Date, progressType: ProgressType) {
        self.id = id
        self.itemId = itemId
        self.additionalId = additionalId
        self.duration = duration
        self.currentTime = currentTime
        self.progress = progress
        self.startedAt = startedAt
        self.lastUpdate = lastUpdate
        self.progressType = progressType
    }
}

// MARK: Types

extension OfflineProgress {
    enum ProgressType: Int, Codable {
        case receivedFromServer = 0
        case localSynced = 1
        case localCached = 2
    }
}

// MARK: progress

extension OfflineProgress {
    func readableProgress(spaceConstrained: Bool = true) -> String {
        let remainingTime = max(duration - currentTime, 0)
        
        if remainingTime <= 5 {
            return "100%"
        } else {
            return remainingTime.timeLeft()
        }
    }
}
