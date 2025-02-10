//
//  Series+Filter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 10.02.25.
//

import Foundation
import SPFoundation

public extension Series {
    func isIncluded(in filter: ItemFilter) async -> Bool {
        await Self.isIncluded(in: filter, id: id, audiobookIDs: audiobooks.map(\.id))
    }
    
    static func isIncluded(in filter: ItemFilter, id: ItemIdentifier, audiobookIDs: [ItemIdentifier]) async -> Bool {
        var progress = [Percentage]()
        
        for audiobookID in audiobookIDs {
            progress.append(await PersistenceManager.shared.progress[audiobookID].progress)
        }
        
        let passed: Bool
        
        switch filter {
        case .all:
            passed = true
        case .active:
            passed = progress.reduce(false) { $0 || ($1 > 0 && $1 < 1) }
        case .finished:
            passed = progress.allSatisfy { $0 >= 1 }
        case .notFinished:
            passed = progress.reduce(false) { $0 || $1 < 1 }
        }
        
        return passed
    }
}
