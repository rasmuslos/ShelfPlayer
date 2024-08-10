//
//  OfflineSession.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData

@Model
public final class ItemProgress: Identifiable {
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

public extension ItemProgress {
    enum ProgressType: Int, Codable, Equatable, Identifiable {
        case receivedFromServer = 0
        case localSynced = 1
        case localCached = 2
    }
}
