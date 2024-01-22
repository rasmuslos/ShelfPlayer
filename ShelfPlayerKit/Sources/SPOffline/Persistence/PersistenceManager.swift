//
//  PersistenceManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import SwiftData

public struct PersistenceManager {
    public let modelContainer: ModelContainer = {
        let schema = Schema([
            OfflineTrack.self,
            OfflineChapter.self,
            OfflineProgress.self,
            
            OfflineAudiobook.self,
            
            OfflinePodcast.self,
            OfflineEpisode.self,
        ], version: .init(1, 0, 0))
        
        #if DISABLE_APP_GROUP
        #warning("SwiftData database will not be stored in group container")
        let modelConfiguration = ModelConfiguration("ShelfPlayer", schema: schema, isStoredInMemoryOnly: false, allowsSave: true)
        #else
        let modelConfiguration = ModelConfiguration("ShelfPlayer", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: .identifier("group.io.rfk.shelfplayer"))
        #endif
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

// MARK: Singleton

public extension PersistenceManager {
    static let shared = PersistenceManager()
}
