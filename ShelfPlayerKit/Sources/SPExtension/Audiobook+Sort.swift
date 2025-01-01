//
//  Audiobook+Sort.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.11.24.
//

import Foundation
import SPFoundation
import SPPersistence

public extension Audiobook {
    static func sort(_ audiobooks: [Audiobook], sortOrder: AudiobookSortOrder, ascending: Bool) -> [Audiobook] {
        let audiobooks = audiobooks.sorted { compare($0, $1, sortOrder) }
        
        // Reverse if not ascending
        if ascending {
            return audiobooks
        } else {
            return audiobooks.reversed()
        }
    }
    
    static func compare(_ lhs: Audiobook, _ rhs: Audiobook, _ sortOrder: AudiobookSortOrder) -> Bool {
        switch sortOrder {
        case .sortName:
            return lhs.sortName.localizedStandardCompare(rhs.sortName) == .orderedAscending
        case .authorName:
            return lhs.authors.joined(separator: ", ").localizedStandardCompare(rhs.authors.joined(separator: ", ") ) == .orderedAscending
        case .released:
            guard let lhsReleased = lhs.released else {
                return false
            }
            guard let rhsReleased = rhs.released else {
                return true
            }
            
            return lhsReleased < rhsReleased
        case .added:
            return lhs.addedAt < rhs.addedAt
        case .duration:
            return lhs.duration < rhs.duration
            
        case .lastPlayed:
            return false
        }
    }
}
