//
//  PersistedSearchIndexEntry.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData


extension SchemaV2 {
    @Model
    final class PersistedSearchIndexEntry {
        #Index<PersistedSearchIndexEntry>([\._itemID, \.primaryName, \.secondaryName, \.authors])
        #Unique<PersistedSearchIndexEntry>([\._itemID])
        
        private var _itemID: String
        
        private(set) var primaryName: String
        private(set) var secondaryName: String?
        
        private(set) var authors: [String]
        private(set) var authorName: String
        
        init(itemID: ItemIdentifier, primaryName: String, secondaryName: String?, authors: [String]) {
            _itemID = itemID.description
            self.primaryName = primaryName
            self.secondaryName = secondaryName
            self.authors = authors
            
            authorName = authors.joined(separator: ", ")
        }
        
        var itemID: ItemIdentifier {
            .init(string: _itemID)
        }
    }
}
