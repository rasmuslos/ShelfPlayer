//
//  Filter+Label.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.09.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal extension AudiobookSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .sortName:
            "sort.name"
        case .authorName:
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
