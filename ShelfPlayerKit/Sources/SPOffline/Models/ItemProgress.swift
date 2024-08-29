//
//  OfflineSession.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData
import SPFoundation

@Model
public final class ItemProgress: Identifiable {
    @Attribute(.unique)
    public let id: String
    public let itemId: String
    public let episodeId: String?
    
    public var duration: TimeInterval
    public var currentTime: TimeInterval
    public var progress: Percentage
    
    public var startedAt: Date
    public var lastUpdate: Date
    
    public var progressType: ProgressType
    
    public init(id: String, itemId: String, episodeId: String?, duration: TimeInterval, currentTime: TimeInterval, progress: Percentage, startedAt: Date, lastUpdate: Date, progressType: ProgressType) {
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

public extension ItemProgress {
    enum ProgressType: Int, Codable, Equatable, Identifiable {
        case receivedFromServer = 0
        case localSynced = 1
        case localCached = 2
        
        public var id: Int {
            rawValue
        }
    }
}
