//
//  PlayableItem+Filter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 01.02.25.
//

import Foundation
import SPFoundation

public extension PlayableItem {
    func isIncluded(in filter: ItemFilter) async -> Bool {
        let included: Bool
        let entity = await PersistenceManager.shared.progress[id]
        
        switch filter {
        case .all:
            included = true
        case .active:
            included = entity.progress > 0 && entity.progress < 1
        case .finished:
            included = entity.isFinished
        case .notFinished:
            included = !entity.isFinished
        }
        
        return included
    }
}
