//
//  OfflineChapter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@Model
public class OfflineChapter {
    public let id: Int
    public let itemId: String
    
    public let start: Double
    public let end: Double
    public let title: String
    
    public init(id: Int, itemId: String, start: Double, end: Double, title: String) {
        self.id = id
        self.itemId = itemId
        self.start = start
        self.end = end
        self.title = title
    }
}
