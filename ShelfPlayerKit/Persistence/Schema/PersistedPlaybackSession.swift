//
//  PersistedPlaybackSession.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedPlaybackSession {
        #Index<PersistedPlaybackSession>([\.id], [\._itemID])
        #Unique<PersistedPlaybackSession>([\.id], [\._itemID])

        @Attribute(.unique)
        public private(set) var id: UUID
        public private(set) var _itemID: String

        public var duration: TimeInterval
        public var currentTime: TimeInterval

        public private(set) var startTime: TimeInterval
        public var timeListened: TimeInterval

        public var started: Date
        public var lastUpdated: Date

        public var eligibleForEarlySync: Bool

        public init(itemID: ItemIdentifier, duration: TimeInterval, currentTime: TimeInterval, startTime: TimeInterval, timeListened: TimeInterval) {
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

        public var itemID: ItemIdentifier {
            .init(string: _itemID)
        }
    }
}
