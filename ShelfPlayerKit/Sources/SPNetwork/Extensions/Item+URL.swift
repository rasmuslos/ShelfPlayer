//
//  Item+URL.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 30.09.24.
//

import Foundation
import SPFoundation

public extension Item {
    var url: URL {
        switch self.type {
        case .author:
            AudiobookshelfClient.shared.serverUrl.appending(path: "author").appending(path: id)
        case .series:
            AudiobookshelfClient.shared.serverUrl.appending(path: "library").appending(path: libraryID).appending(path: "series").appending(path: id)
        default:
            AudiobookshelfClient.shared.serverUrl.appending(path: "item").appending(path: identifiers.itemID)
        }
     }
}
