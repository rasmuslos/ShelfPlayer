//
//  SortOrder+ApiValue.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 14.11.24.
//

import Foundation
import SPFoundation

extension AudiobookSortOrder {
    var queryValue: String {
        switch self {
        case .sortName:
            "media.metadata.title"
        case .authorName:
            "media.metadata.authorName"
        case .released:
            "media.metadata.publishedYear"
        case .added:
            "addedAt"
        case .duration:
            "media.duration"
        case .lastPlayed:
            ""
        }
    }
}

extension SeriesSortOrder {
    var queryValue: String {
        switch self {
        case .sortName:
            "name"
        case .bookCount:
            "numBooks"
        case .added:
            "addedAt"
        case .duration:
            "totalDuration"
        }
    }
}
