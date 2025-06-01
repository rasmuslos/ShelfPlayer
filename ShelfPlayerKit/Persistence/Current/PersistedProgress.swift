//
//  PersistedProgress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import SwiftData


extension SchemaV2 {
    @Model
    final class PersistedProgress {
        #Index<PersistedProgress>([\.id], [\.connectionID, \.primaryID, \.groupingID])
        #Unique<PersistedProgress>([\.id], [\.connectionID, \.primaryID, \.groupingID])
        
        private(set) var id: String
        
        private(set) var connectionID: String
        
        private(set) var primaryID: String
        private(set) var groupingID: String?
        
        var progress: Percentage
        
        var duration: TimeInterval?
        var currentTime: TimeInterval
        
        var startedAt: Date?
        var lastUpdate: Date
        var finishedAt: Date?
        
        var status: SyncStatus
        
        init(id: String, connectionID: String, primaryID: String, groupingID: String?, progress: Percentage, duration: TimeInterval? = nil, currentTime: TimeInterval, startedAt: Date? = nil, lastUpdate: Date, finishedAt: Date? = nil, status: SyncStatus) {
            self.id = id
            
            self.connectionID = connectionID
            self.primaryID = primaryID
            self.groupingID = groupingID
            
            self.progress = progress
            
            self.duration = duration
            self.currentTime = currentTime
            
            self.startedAt = startedAt
            self.lastUpdate = lastUpdate
            self.finishedAt = finishedAt
            
            self.status = status
        }
        
        enum SyncStatus: Int, Codable {
            case synchronized
            case desynchronized
            case tombstone
        }
    }
}
