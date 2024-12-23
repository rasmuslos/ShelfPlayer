//
//  PlaybackSpeedOverride.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation
import SwiftData
import SPFoundation

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
extension SchemaV1 {
    @Model
    public final class PlaybackSpeedOverride {
        public var itemID: String
        public var episodeID: String?
        
        public var speed: Percentage
        
        init (itemID: String, episodeID: String?, speed: Percentage) {
            self.itemID = itemID
            self.episodeID = episodeID
            self.speed = speed
        }
    }
}
