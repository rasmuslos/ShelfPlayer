//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 14.04.24.
//

import Foundation
import SwiftData

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
extension SchemaV1 {
    @Model
    public final class Bookmark {
        public var itemId: String
        // episodes are not supported by ABS right now, but i will leave this here
        public var episodeId: String?
        
        public var note: String
        public var position: TimeInterval
        
        internal var status: SyncStatus
        
        internal init(itemId: String, episodeId: String?, note: String, position: TimeInterval, status: SyncStatus) {
            self.itemId = itemId
            self.episodeId = episodeId
            self.note = note
            self.position = position
            self.status = status
        }
    }
}

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
internal extension SchemaV1.Bookmark {
    enum SyncStatus: Int, Codable {
        case synced = 0
        case deleted = 2
        case pendingUpdate = 3
        case pendingCreation = 1
    }
}
