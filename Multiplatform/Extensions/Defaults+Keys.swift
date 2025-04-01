//
//  Defaults+Keys.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import Foundation
import Defaults
import ShelfPlayerKit

extension Defaults.Keys {
    static let lastTabValue = Key<TabValue?>("lastTabValue")
    
    static let tintColor = Key("tintColor", default: TintPicker.TintColor.shelfPlayer)
    
    static let lastSpotlightIndex = Key<Date?>("lastSpotlightIndex", default: nil)
    static let indexedIdentifiers = Key<[String]>("indexedIdentifiers", default: [])
    
    static let carPlayTabBarLibraries = Key<[Library]?>("carPlayTabBarLibraries", default: nil)
}
