//
//  PersistedListeningDay.swift
//  ShelfPlayerKit
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedListeningDay {
        #Index<PersistedListeningDay>([\.compositeKey], [\.connectionID], [\.dayKey])
        #Unique<PersistedListeningDay>([\.compositeKey])

        public private(set) var compositeKey: String
        public private(set) var connectionID: String
        public private(set) var dayKey: String
        public var seconds: Double
        public private(set) var capturedAt: Date

        public init(connectionID: String, dayKey: String, seconds: Double, capturedAt: Date = .now) {
            self.compositeKey = "\(connectionID)::\(dayKey)"
            self.connectionID = connectionID
            self.dayKey = dayKey
            self.seconds = seconds
            self.capturedAt = capturedAt
        }
    }
}
