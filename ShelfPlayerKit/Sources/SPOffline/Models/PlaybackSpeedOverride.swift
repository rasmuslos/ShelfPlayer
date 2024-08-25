//
//  PlaybackSpeedOverride.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation
import SwiftData

@Model
public final class PlaybackSpeedOverride {
    public let itemID: String
    public let episodeID: String?
    
    public var speed: Float
    
    init (itemID: String, episodeID: String?, speed: Float) {
        self.itemID = itemID
        self.episodeID = episodeID
        self.speed = speed
    }
}
