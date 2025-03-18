//
//  PersistedChapter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedPlaybackSession {
        #Index<PersistedPlaybackSession>([\.id], [\._itemID])
        #Unique<PersistedPlaybackSession>([\.id], [\._itemID])
        
        @Attribute(.unique)
        private(set) var id: UUID
        private(set) var _itemID: String
        
        var duration: TimeInterval
        var currentTime: TimeInterval
        
        private(set) var startTime: TimeInterval
        var timeListened: TimeInterval
        
        var started: Date
        var lastUpdated: Date
        
        var eligibleForEarlySync: Bool
        
        init(itemID: ItemIdentifier, duration: TimeInterval, currentTime: TimeInterval, startTime: TimeInterval, timeListened: TimeInterval) {
            id = .init()
            _itemID = itemID.description
            
            self.duration = duration
            self.currentTime = currentTime
            
            self.startTime = startTime
            self.timeListened = timeListened
            
            started = .now
            lastUpdated = .now
            
            eligibleForEarlySync = false
        }
        
        var itemID: ItemIdentifier {
            .init(_itemID)
        }
    }
}
