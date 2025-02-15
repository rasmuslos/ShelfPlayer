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
        #Index<PersistedChapter>([\.id], [\._itemID])
        #Unique<PersistedChapter>([\.id], [\._itemID, \.start])
        
        @Attribute(.unique)
        private(set) var id: UUID
        private(set) var _itemID: String
        
        private(set) var name: String
        
        private(set) var start: TimeInterval
        private(set) var end: TimeInterval
        
        init(id: UUID, itemID: ItemIdentifier, name: String, start: TimeInterval, end: TimeInterval) {
            self.id = id
            _itemID = itemID.description
            self.name = name
            self.start = start
            self.end = end
        }
        
        var itemID: ItemIdentifier {
            .init(_itemID)
        }
    }
}
