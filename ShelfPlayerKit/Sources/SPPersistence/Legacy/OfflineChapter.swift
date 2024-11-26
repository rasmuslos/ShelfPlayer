//
//  OfflineChapter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    public final class OfflineChapter {
        public let id: Int
        public let itemId: String
        
        public let start: TimeInterval
        public let end: TimeInterval
        public let title: String
        
        public init(id: Int, itemId: String, start: TimeInterval, end: TimeInterval, title: String) {
            self.id = id
            self.itemId = itemId
            self.start = start
            self.end = end
            self.title = title
        }
    }
}
