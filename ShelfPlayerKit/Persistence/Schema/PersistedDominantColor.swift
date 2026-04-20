//
//  PersistedDominantColor.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedDominantColor {
        #Index<PersistedDominantColor>([\.itemID])
        #Unique<PersistedDominantColor>([\.itemID])

        public private(set) var itemID: String
        public var red: Double
        public var green: Double
        public var blue: Double

        public init(itemID: String, red: Double, green: Double, blue: Double) {
            self.itemID = itemID
            self.red = red
            self.green = green
            self.blue = blue
        }
    }
}
