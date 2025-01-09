//
//  PersistedChapter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedChapter {
        #Index<PersistedChapter>([\.id], [\.itemID])
        #Unique<PersistedChapter>([\.id], [\.itemID, \.start])
        
        @Attribute(.unique)
        private(set) var id: UUID
        @Attribute(.transformable(by: ItemIdentifierTransformer.self))
        private(set) var itemID: ItemIdentifier
        
        private(set) var name: String
        
        private(set) var start: TimeInterval
        private(set) var end: TimeInterval
        
        init(id: UUID, itemID: ItemIdentifier, name: String, start: TimeInterval, end: TimeInterval) {
            self.id = id
            self.itemID = itemID
            self.name = name
            self.start = start
            self.end = end
        }
    }
}
