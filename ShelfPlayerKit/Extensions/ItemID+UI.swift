//
//  ItemID+UI.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import SwiftUI

private let bundle = Bundle(for: ItemIdentifier.self)

public extension ItemIdentifier.ItemType {
    var label: String {
        switch self {
            case .audiobook:
                String(localized: "item.audiobook", bundle: bundle)
            case .author:
                String(localized: "item.author", bundle: bundle)
            case .narrator:
                String(localized: "item.narrator", bundle: bundle)
            case .series:
                String(localized: "item.series", bundle: bundle)
            case .podcast:
                String(localized: "item.podcast", bundle: bundle)
            case .episode:
                String(localized: "item.episode", bundle: bundle)
            case .collection:
                String(localized: "item.collection", bundle: bundle)
            case .playlist:
                String(localized: "item.playlist", bundle: bundle)
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
