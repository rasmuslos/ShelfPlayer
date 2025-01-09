//
//  PersistedBookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedBookmark {
        #Index<PersistedBookmark>([\.id], [\.itemID])
        #Unique<PersistedBookmark>([\.id], [\.itemID, \.time])
        
        @Attribute(.unique)
        private(set) var id = UUID()
        @Attribute(.transformable(by: ItemIdentifierTransformer.self))
        private(set) var itemID: ItemIdentifier
        
        private(set) var time: UInt64
        var note: String
        
        private(set) var created: Date
        
        var status: SyncStatus
        
        init(itemID: ItemIdentifier, time: UInt64, note: String, created: Date, status: SyncStatus) {
            self.itemID = itemID
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
