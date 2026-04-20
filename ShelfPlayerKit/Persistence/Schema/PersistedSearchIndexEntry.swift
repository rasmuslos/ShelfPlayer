//
//  PersistedSearchIndexEntry.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedSearchIndexEntry {
        #Index<PersistedSearchIndexEntry>([\._itemID, \.primaryName, \.secondaryName, \.authors])
        #Unique<PersistedSearchIndexEntry>([\._itemID])

        public private(set) var _itemID: String

        public private(set) var primaryName: String
        public private(set) var secondaryName: String?

        public private(set) var authors: [String]
        public private(set) var authorName: String

        public init(itemID: ItemIdentifier, primaryName: String, secondaryName: String?, authors: [String]) {
            _itemID = itemID.description
            self.primaryName = primaryName
            self.secondaryName = secondaryName
            self.authors = authors

            authorName = authors.joined(separator: ", ")
        }

        public var itemID: ItemIdentifier {
            .init(string: _itemID)
        }
    }
}
