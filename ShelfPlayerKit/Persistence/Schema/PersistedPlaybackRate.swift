//
//  PersistedPlaybackRate.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedPlaybackRate {
        #Index<PersistedPlaybackRate>([\.itemID])
        #Unique<PersistedPlaybackRate>([\.itemID])

        public private(set) var itemID: String
        public var rate: Double
        public var isCachePurgeable: Bool

        public init(itemID: String, rate: Double, isCachePurgeable: Bool = false) {
            self.itemID = itemID
            self.rate = rate
            self.isCachePurgeable = isCachePurgeable
        }
    }
}
