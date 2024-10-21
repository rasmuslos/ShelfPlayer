//
//  Filter+Label.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.09.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal extension ItemFilter {
    var label: LocalizedStringKey {
        switch self {
            case .all:
                "filter.all"
            case .progress:
                "filter.inProgress"
            case .unfinished:
                "filter.unfinished"
            case .finished:
                "filter.finished"
        }
    }
}

internal extension ItemDisplayType {
    var label: LocalizedStringKey {
        switch self {
        case .grid:
            "display.grid"
        case .list:
            "display.list"
        }
    }
    
    var icon: String {
        switch self {
        case .grid:
            "square.grid.2x2"
        case .list:
            "list.bullet"
        }
    }
}

internal extension AudiobookSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .name:
            "sort.name"
        case .series:
            "sort.series"
        case .author:
            "sort.author"
        case .released:
            "sort.released"
        case .added:
            "sort.added"
        case .duration:
            "sort.duration"
        case .lastPlayed:
            "sort.lastPlayed"
        }
    }
}

internal extension EpisodeSortOrder {
    var label: LocalizedStringKey {
        switch self {
            case .name:
                "sort.name"
            case .index:
                "sort.index"
            case .released:
                "sort.released"
            case .duration:
                "sort.duration"
        }
    }
}
