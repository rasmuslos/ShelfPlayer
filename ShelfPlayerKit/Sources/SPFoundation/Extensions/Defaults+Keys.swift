//
//  Defaults+Keys.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 29.10.24.
//

import Foundation
import Defaults

public extension Defaults.Keys {
    static let skipForwardsInterval = Key<Int>("skipForwardsInterval", default: 30)
    static let skipBackwardsInterval = Key<Int>("skipBackwardsInterval", default: 30)
    
    static func groupingFilter(_ itemID: ItemIdentifier) -> Defaults.Key<ItemFilter> {
        .init("grouping-filter-\(itemID.groupingID ?? itemID.primaryID)", default: .notFinished)
    }
    
    static func groupingAscending(_ itemID: ItemIdentifier) -> Defaults.Key<Bool> {
        .init("grouping-ascending-\(itemID.groupingID ?? itemID.primaryID)", default: false)
    }
    static func groupingSortOrder(_ itemID: ItemIdentifier) -> Defaults.Key<EpisodeSortOrder> {
        .init("grouping-sort-\(itemID.groupingID ?? itemID.primaryID)", default: .released)
    }
}
