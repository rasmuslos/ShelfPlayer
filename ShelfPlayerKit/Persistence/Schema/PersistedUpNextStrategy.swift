//
//  PersistedUpNextStrategy.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedUpNextStrategy {
        #Index<PersistedUpNextStrategy>([\.itemID])
        #Unique<PersistedUpNextStrategy>([\.itemID])

        public private(set) var itemID: String
        public var strategy: String
        public var allowSuggestions: Bool?

        public init(itemID: String, strategy: String, allowSuggestions: Bool? = nil) {
            self.itemID = itemID
            self.strategy = strategy
            self.allowSuggestions = allowSuggestions
        }
    }
}
