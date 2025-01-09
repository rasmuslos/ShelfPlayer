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
        #Index<PersistedSearchIndexEntry>([\.itemID, \.primaryName, \.secondaryName, \.authors])
        #Unique<PersistedSearchIndexEntry>([\.itemID])
        
        @Attribute(.transformable(by: ItemIdentifierTransformer.self))
        private(set) var itemID: ItemIdentifier
        
        private(set) var primaryName: String
        private(set) var secondaryName: String?
        
        private(set) var authors: [String]
        
        init(itemID: ItemIdentifier, primaryName: String, secondaryName: String? = nil, authors: [String]) {
            self.itemID = itemID
            self.primaryName = primaryName
            self.secondaryName = secondaryName
            self.authors = authors
        }
    }
}
