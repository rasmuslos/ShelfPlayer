//
//  PersistedListenNowSuggestion.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import Foundation
import SwiftData

extension SchemaV2 {
    @Model
    final class PersistedListenNowSuggestion {
        private(set) var _itemID: String
        private(set) var type: SuggestionType
        
        private(set) var created: Date
        private(set) var validUntil: Date
        
        init(itemID: ItemIdentifier, type: SuggestionType, validUntil: Date) {
            self._itemID = itemID.description
            self.type = type
            
            created = .now
            self.validUntil = validUntil
        }
        
        var itemID: ItemIdentifier {
            .init(_itemID)
        }
        
        enum SuggestionType: Int, Codable {
            case groupingFinishedPlaying
        }
    }
}

