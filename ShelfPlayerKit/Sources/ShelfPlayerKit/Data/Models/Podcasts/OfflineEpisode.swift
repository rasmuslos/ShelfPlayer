//
//  OfflineEpisode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData

@Model
class OfflineEpisode {
    let id: String
    let libraryId: String
    
    let name: String
    let author: String?
    
    let overview: String?
    
    let addedAt: Date
    let released: String?
    
    @Relationship
    var podcast: OfflinePodcast!
    
    let index: Int
    let duration: Double
    
    var downloadCompleted: Bool
    
    init(id: String, libraryId: String, name: String, author: String?, overview: String?, addedAt: Date, released: String?, index: Int, duration: Double) {
        self.id = id
        self.libraryId = libraryId
        self.name = name
        self.author = author
        self.overview = overview
        self.addedAt = addedAt
        self.released = released
        self.index = index
        self.duration = duration
        
        podcast = nil
        downloadCompleted = false
    }
}
