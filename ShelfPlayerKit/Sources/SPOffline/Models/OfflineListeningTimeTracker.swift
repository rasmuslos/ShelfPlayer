//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.04.24.
//

import Foundation
import SwiftData

@Model
public final class OfflineListeningTimeTracker: Identifiable {
    @Attribute(.unique)
    public var id: String
    
    public var itemId: String
    public var episodeId: String?
    
    public var started: Date
    public var startTime: Double
    
    public var duration: Double
    public var lastUpdate: Date
    
    public var eligibleForSync: Bool
    
    public init(id: String, itemId: String, episodeId: String?) {
        self.id = id
        
        self.itemId = itemId
        self.episodeId = episodeId
        
        duration = 0
        startTime = .nan
        
        started = Date()
        lastUpdate = Date()
        
        eligibleForSync = false
    }
}
