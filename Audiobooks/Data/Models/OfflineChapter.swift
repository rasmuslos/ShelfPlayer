//
//  OfflineChapter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@Model
class OfflineChapter {
    let id: Int
    let itemId: String
    
    let start: Double
    let end: Double
    let title: String
    
    init(id: Int, itemId: String, start: Double, end: Double, title: String) {
        self.id = id
        self.itemId = itemId
        self.start = start
        self.end = end
        self.title = title
    }
}
