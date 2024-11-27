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
    final class PersistedSearchIndexEntry {
        @Attribute(.unique)
        private(set) var itemID: ItemIdentifier
        
        private(set) var primaryName: String
        private(set) var secondaryName: String?
        
        private(set) var author: [String]
        
        init(itemID: ItemIdentifier, primaryName: String, secondaryName: String? = nil, author: [String]) {
            self.itemID = itemID
            self.primaryName = primaryName
            self.secondaryName = secondaryName
            self.author = author
        }
    }
}
