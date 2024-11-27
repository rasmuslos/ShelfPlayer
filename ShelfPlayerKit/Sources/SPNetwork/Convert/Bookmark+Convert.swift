//
//  Bookmark+Convert.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SPFoundation

extension Bookmark {
    init(payload: BookmarkPayload) {
        self.init(itemID: .init(primaryID: payload.libraryItemId, groupingID: nil), time: .init(payload.time), note: payload.title, created: .init(timeIntervalSince1970: payload.createdAt))
    }
}
