//
//  PersistedChapter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedChapter {
        #Index<PersistedChapter>([\.id], [\._itemID])
        #Unique<PersistedChapter>([\.id], [\._itemID, \.startOffset])

        @Attribute(.unique)
        public private(set) var id: UUID
        public private(set) var index: Int
        public private(set) var _itemID: String

        public private(set) var name: String

        public private(set) var startOffset: TimeInterval
        public private(set) var endOffset: TimeInterval

        public init(index: Int, itemID: ItemIdentifier, name: String, startOffset: TimeInterval, endOffset: TimeInterval) {
            self.id = .init()
            self.index = index
            _itemID = itemID.description
            self.name = name
            self.startOffset = startOffset
            self.endOffset = endOffset
        }

        public var itemID: ItemIdentifier {
            .init(string: _itemID)
        }
    }
}
