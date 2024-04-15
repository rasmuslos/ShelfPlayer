//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 14.04.24.
//

import Foundation
import SwiftData

@Model
public final class Bookmark {
    public let itemId: String
    // episodes are not supported by ABS right now, but i will leave this here
    public let episodeId: String?
    
    public let note: String
    public let position: Double
    
    var status: SyncStatus
    
    init(itemId: String, episodeId: String?, note: String, position: Double, status: SyncStatus) {
        self.itemId = itemId
        self.episodeId = episodeId
        self.note = note
        self.position = position
        self.status = status
    }
}

extension Bookmark {
    enum SyncStatus: Int, Codable {
        case synced = 0
        case pending = 1
        case deleted = 2
    }
}
