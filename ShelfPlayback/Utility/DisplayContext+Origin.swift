//
//  DisplayContext+Origin.swift
//  ShelfPlayback
//
//  Created by Rasmus Krämer on 13.07.25.
//

import Foundation
import ShelfPlayerKit

public extension DisplayContext {
    var origin: AudioPlayerItem.PlaybackOrigin {
        switch self {
            case .series(let series): .series(series.id)
            case .collection(let collection): .collection(collection.id)
            default: .unknown
        }
    }
}
