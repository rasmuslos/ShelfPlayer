//
//  PersistedProgress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedProgress {
        #Index<PersistedProgress>([\.id], [\.connectionID, \.primaryID, \.groupingID])
        #Unique<PersistedProgress>([\.id], [\.connectionID, \.primaryID, \.groupingID])

        public var id: String

        public private(set) var connectionID: String

        public private(set) var primaryID: String
        public private(set) var groupingID: String?

        public var progress: Percentage

        public var duration: TimeInterval?
        public var currentTime: TimeInterval

        public var startedAt: Date?
        public var lastUpdate: Date
        public var finishedAt: Date?

        public var status: SyncStatus = SyncStatus.desynchronized
        public var hasBeenSynchronised = true

        public init(id: String, connectionID: String, primaryID: String, groupingID: String?, progress: Percentage, duration: TimeInterval? = nil, currentTime: TimeInterval, startedAt: Date? = nil, lastUpdate: Date, finishedAt: Date? = nil, status: SyncStatus) {
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

        public enum SyncStatus: Int, Codable {
            case synchronized
            case desynchronized
            case tombstone
        }
    }
}
