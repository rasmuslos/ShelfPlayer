//
//  OfflineSession.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData
import SPBaseKit

@Model
public class OfflineProgress: Identifiable {
    @Attribute(.unique)
    public let id: String
    public let itemId: String
    public let episodeId: String?
    
    public var duration: Double
    public var currentTime: Double
    public var progress: Double
    
    public var startedAt: Date
    public var lastUpdate: Date
    
    public var progressType: ProgressType
    
    public init(id: String, itemId: String, episodeId: String?, duration: Double, currentTime: Double, progress: Double, startedAt: Date, lastUpdate: Date, progressType: ProgressType) {
        self.id = id
        self.itemId = itemId
        self.episodeId = episodeId
        self.duration = duration
        self.currentTime = currentTime
        self.progress = progress
        self.startedAt = startedAt
        self.lastUpdate = lastUpdate
        self.progressType = progressType
    }
}

public extension OfflineProgress {
    enum ProgressType: Int, Codable, Equatable {
        case receivedFromServer = 0
        case localSynced = 1
        case localCached = 2
    }
}

public extension OfflineProgress {
    func readableProgress(spaceConstrained: Bool = true) -> String {
        let remainingTime = max(duration - currentTime, 0)
        
        if remainingTime <= 5 {
            return "100%"
        } else {
            return remainingTime.timeLeft(spaceConstrained: spaceConstrained)
        }
    }
}
