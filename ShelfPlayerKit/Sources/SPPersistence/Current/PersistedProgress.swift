//
//  PersistedProgress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedProgress {
        #Index<PersistedProgress>([\.id], [\.itemID])
        #Unique<PersistedProgress>([\.id], [\.itemID])
        
        private(set) var id: String
        @Attribute(.transformable(by: ItemIdentifierTransformer.self))
        private(set) var itemID: ItemIdentifier
        
        var progress: Percentage
        
        var duration: TimeInterval
        var currentTime: TimeInterval
        
        var startedAt: Date?
        var lastUpdate: Date
        var finishedAt: Date?
        
        var status: SyncStatus
        
        init(id: String, itemID: ItemIdentifier, progress: Percentage, duration: TimeInterval, currentTime: TimeInterval, startedAt: Date?, lastUpdate: Date, finishedAt: Date?, status: SyncStatus) {
            self.id = id
            self.itemID = itemID
            
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
