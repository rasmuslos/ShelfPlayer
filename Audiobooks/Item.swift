//
//  Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
