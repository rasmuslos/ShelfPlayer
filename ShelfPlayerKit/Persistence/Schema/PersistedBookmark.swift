//
//  PersistedBookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedBookmark {
        #Index<PersistedBookmark>([\.id], [\.connectionID, \.primaryID])
        #Unique<PersistedBookmark>([\.id], [\.connectionID, \.primaryID, \.time])

        @Attribute(.unique)
        public private(set) var id = UUID()

        public private(set) var primaryID: ItemIdentifier.PrimaryID
        public private(set) var connectionID: ItemIdentifier.ConnectionID

        public private(set) var time: UInt64
        public var note: String

        public var created: Date

        public var status: SyncStatus = SyncStatus.pendingCreation

        public init(connectionID: ItemIdentifier.ConnectionID, primaryID: ItemIdentifier.PrimaryID, time: UInt64, note: String, created: Date, status: SyncStatus) {
            self.connectionID = connectionID
            self.primaryID = primaryID
            self.time = time
            self.note = note
            self.created = created

            self.status = status
        }

        public enum SyncStatus: Int, Codable {
            case synced
            case deleted
            case pendingUpdate
            case pendingCreation
        }
    }
}
