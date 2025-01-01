//
//  PlaybackReporter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import Foundation
import Defaults
import SPFoundation
import SPNetwork
import SPPersistence

final actor PlaybackReporter {
    let itemID: ItemIdentifier
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
    }
}
