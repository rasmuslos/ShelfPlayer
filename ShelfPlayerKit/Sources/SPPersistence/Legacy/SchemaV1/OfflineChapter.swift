//
//  OfflineChapter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
extension SchemaV1 {
    @Model
    final class OfflineChapter {
        var id: Int
        var itemId: String
        
        var start: TimeInterval
        var end: TimeInterval
        var title: String
        
        init(id: Int, itemId: String, start: TimeInterval, end: TimeInterval, title: String) {
            self.id = id
            self.itemId = itemId
            self.start = start
            self.end = end
            self.title = title
        }
    }
}
