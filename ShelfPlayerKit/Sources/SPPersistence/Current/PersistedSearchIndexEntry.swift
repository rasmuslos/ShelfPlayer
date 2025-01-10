//
//  PersistedSearchIndexEntry.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedSearchIndexEntry {
        #Index<PersistedSearchIndexEntry>([\._itemID, \.primaryName, \.secondaryName, \.authors])
        #Unique<PersistedSearchIndexEntry>([\._itemID])
        
        private var _itemID: String
        
        private(set) var primaryName: String
        private(set) var secondaryName: String?
        
        private(set) var authors: [String]
        
        init(itemID: ItemIdentifier, primaryName: String, secondaryName: String? = nil, authors: [String]) {
            _itemID = itemID.description
            self.primaryName = primaryName
            self.secondaryName = secondaryName
            self.authors = authors
        }
        
        var itemID: ItemIdentifier {
            .init(_itemID)
        }
    }
}
