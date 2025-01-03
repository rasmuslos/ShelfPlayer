//
//  OfflineProgress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 17.09.24.
//

import Foundation
import SwiftData
import SPFoundation

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
internal extension SchemaV1 {
    @Model
    class OfflineProgress {
        @Attribute(.unique)
        var id: String
        var itemID: String
        var episodeID: String?
        
        var progress: Percentage
        
        var duration: TimeInterval
        var currentTime: TimeInterval
        
        var startedAt: Date?
        var lastUpdate: Date
        var finishedAt: Date?
        
        var progressType: ProgressSyncState
        
        init(id: String, itemID: String, episodeID: String?, progress: Percentage, duration: TimeInterval, currentTime: TimeInterval, startedAt: Date?, lastUpdate: Date, finishedAt: Date?, progressType: ProgressSyncState) {
            self.id = id
            self.itemID = itemID
            self.episodeID = episodeID
            
            self.progress = progress
            
            self.duration = duration
            self.currentTime = currentTime
            
            self.startedAt = startedAt
            self.lastUpdate = lastUpdate
            self.finishedAt = finishedAt
            
            self.progressType = progressType
        }
    }
}

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
internal extension SchemaV1.OfflineProgress {
    enum ProgressSyncState: Int, Codable, Equatable, Identifiable {
        case receivedFromConnection = 0
        case localSynced = 1
        case localCached = 2
        
        public var id: Int {
            rawValue
        }
    }
}
