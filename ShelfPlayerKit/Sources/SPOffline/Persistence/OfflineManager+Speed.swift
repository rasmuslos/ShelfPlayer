//
//  OfflineManager+Speed.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation
import SwiftData

public extension OfflineManager {
    func playbackSpeed(for itemID: String, episodeID: String?) -> Float {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        var descriptor = FetchDescriptor<PlaybackSpeedOverride>(predicate: #Predicate { $0.itemID == itemID && $0.episodeID == episodeID })
        descriptor.fetchLimit = 1
        
        guard let override = try? context.fetch(descriptor).first else {
            if UserDefaults.standard.object(forKey: "defaultPlaybackSpeed") == nil {
                return 1.0
            }
            
            return UserDefaults.standard.float(forKey: "defaultPlaybackSpeed")
        }
        
        return override.speed
    }
    
    func overrideDefaultPlaybackSpeed(_ speed: Float, for itemID: String, episodeID: String?) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if let override = try? context.fetch(.init(predicate: #Predicate<PlaybackSpeedOverride> { $0.itemID == itemID && $0.episodeID == episodeID })).first {
            override.speed = speed
        } else {
            let override = PlaybackSpeedOverride(itemID: itemID, episodeID: episodeID, speed: speed)
            context.insert(override)
        }
        
        try context.save()
    }
    
    func removePlaybackSpeedOverride(for itemID: String, episodeID: String?) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        try? context.delete(model: PlaybackSpeedOverride.self, where: #Predicate { $0.itemID == itemID && $0.episodeID == episodeID })
        try? context.save()
    }
}
