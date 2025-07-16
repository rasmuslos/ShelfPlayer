//
//  ItemID+UI.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import SwiftUI

public extension ItemIdentifier.ItemType {
    var label: String {
        switch self {
            case .audiobook:
                String(localized: "item.audiobook")
            case .author:
                String(localized: "item.author")
            case .narrator:
                String(localized: "item.narrator")
            case .series:
                String(localized: "item.series")
            case .podcast:
                String(localized: "item.podcast")
            case .episode:
                String(localized: "item.episode")
            case .collection:
                String(localized: "item.collection")
            case .playlist:
                String(localized: "item.playlist")
        }
    }
    var icon: String {
        switch self {
            case .audiobook:
                "book.fill"
            case .author:
                "person.fill"
            case .narrator:
                "microphone.fill"
            case .series:
                "rectangle.grid.2x2.fill"
            case .podcast:
                "square.stack"
            case .episode:
                "play.square"
            case .collection:
                "list.triangle"
            case .playlist:
                "list.bullet"
        }
    }
}
