//
//  PersistedBookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData


extension SchemaV2 {
    @Model
    final class PersistedBookmark {
        #Index<PersistedBookmark>([\.id], [\.connectionID, \.primaryID])
        #Unique<PersistedBookmark>([\.id], [\.connectionID, \.primaryID, \.time])
        
        @Attribute(.unique)
        private(set) var id = UUID()
        
        private(set) var primaryID: ItemIdentifier.PrimaryID
        private(set) var connectionID: ItemIdentifier.ConnectionID
        
        private(set) var time: UInt64
        var note: String
        
        var created: Date
        
        var status: SyncStatus
        
        init(connectionID: ItemIdentifier.ConnectionID, primaryID: ItemIdentifier.PrimaryID, time: UInt64, note: String, created: Date, status: SyncStatus) {
            self.connectionID = connectionID
            self.primaryID = primaryID
            self.time = time
            self.note = note
            self.created = created
            
            self.status = status
        }
        
        enum SyncStatus: Int, Codable {
            case synced
            case deleted
            case pendingUpdate
            case pendingCreation
        }
    }
}
