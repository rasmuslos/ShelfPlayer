//
//  Audiobook+Sort.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.11.24.
//

import Foundation
import ShelfPlayerKit

internal extension Audiobook {
    static func filterSort(_ audiobooks: [Audiobook], filter: ItemFilter, sortOrder: AudiobookSortOrder, ascending: Bool) -> [Audiobook] {
        sort(Self.filter(audiobooks, filter: filter), sortOrder: sortOrder, ascending: ascending)
    }
    
    static func filter(_ audiobooks: [Audiobook], filter: ItemFilter) -> [Audiobook] {
        audiobooks.filter { audiobook in
            if filter == .all {
                return true
            }
            
            let entity = OfflineManager.shared.progressEntity(item: audiobook)
            
            if filter == .finished && entity.isFinished {
                return true
            } else if filter == .unfinished && entity.progress < 1 {
                return true
            }
            
            return false
        }
    }
    
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
        case .seriesName:
            for (index, lhs) in lhs.series.enumerated() {
                if index > rhs.series.count - 1 {
                    return true
                }
                
                let rhs = rhs.series[index]
                
                if lhs.name == rhs.name {
                    guard let lhsSequence = lhs.sequence else { return false }
                    guard let rhsSequence = rhs.sequence else { return true }
                    
                    return lhsSequence < rhsSequence
                }
                
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            
            return false
        case .authorName:
            guard let lhsAuthor = lhs.author else {
                return false
            }
            guard let rhsAuthor = rhs.author else {
                return true
            }
            
            return lhsAuthor.localizedStandardCompare(rhsAuthor) == .orderedAscending
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
            return OfflineManager.shared.progressEntity(item: lhs).lastUpdate < OfflineManager.shared.progressEntity(item: rhs).lastUpdate
        }
    }
}
