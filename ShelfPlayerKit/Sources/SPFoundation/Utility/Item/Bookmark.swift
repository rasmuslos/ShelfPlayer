//
//  Bookmark.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation

struct Bookmark {
    let itemID: ItemIdentifier
    
    let time: TimeInterval
    let note: String
    
    let created: Date
}

extension Bookmark: Sendable {}
extension Bookmark: Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}
