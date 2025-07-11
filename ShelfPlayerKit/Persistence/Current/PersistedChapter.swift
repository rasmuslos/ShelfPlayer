//
//  PersistedChapter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData


extension SchemaV2 {
    @Model
    final class PersistedChapter {
        #Index<PersistedChapter>([\.id], [\._itemID])
        #Unique<PersistedChapter>([\.id], [\._itemID, \.startOffset])
        
        @Attribute(.unique)
        private(set) var id: UUID
        private(set) var index: Int
        private(set) var _itemID: String
        
        private(set) var name: String
        
        private(set) var startOffset: TimeInterval
        private(set) var endOffset: TimeInterval
        
        init(index: Int, itemID: ItemIdentifier, name: String, startOffset: TimeInterval, endOffset: TimeInterval) {
            self.id = .init()
            self.index = index
            _itemID = itemID.description
            self.name = name
            self.startOffset = startOffset
            self.endOffset = endOffset
        }
        
        var itemID: ItemIdentifier {
            .init(string: _itemID)
        }
    }
}
