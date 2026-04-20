//
//  PersistedSleepTimerConfig.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedSleepTimerConfig {
        #Index<PersistedSleepTimerConfig>([\.itemID])
        #Unique<PersistedSleepTimerConfig>([\.itemID])

        public private(set) var itemID: String
        public var configData: Data

        public init(itemID: String, configData: Data) {
            self.itemID = itemID
            self.configData = configData
        }
    }
}
