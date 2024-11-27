//
//  Bookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation

public struct Bookmark {
    public let itemID: ItemIdentifier
    
    public let time: UInt64
    public let note: String
    
    public let created: Date
    
    public init(itemID: ItemIdentifier, time: UInt64, note: String, created: Date) {
        self.itemID = itemID
        self.time = time
        self.note = note
        self.created = created
    }
}

extension Bookmark: Sendable {}
extension Bookmark: Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}
