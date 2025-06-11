//
//  PersistedConvenienceDownloadReleation.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 11.06.25.
//

import Foundation
import SwiftData

extension SchemaV2 {
    @Model
    final class PersistedConvenienceDownloadReleation {
        #Index<PersistedConvenienceDownloadReleation>([\._itemID], [\._groupingID])
        
        private var _itemID: String
        private var _groupingID: String
        
        init(itemID: ItemIdentifier, groupingID: ItemIdentifier) {
            _itemID = itemID.description
            _groupingID = groupingID.description
        }
        
        var itemID: ItemIdentifier {
            .init(_itemID)
        }
        var groupingID: ItemIdentifier {
            .init(_groupingID)
        }
    }
}
