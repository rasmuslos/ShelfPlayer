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
            OfflineProgress.self,
            OfflineChapter.self,
            
            DownloadReference.self,
            
            OfflineAudiobook.self,
            OfflineAudiobookTrack.self,
            
            OfflineEpisode.self,
            OfflinePodcast.self,
        ])
        #if DISABLE_APP_GROUP
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
    
    private init() {
    }
}

// MARK: Singleton

extension PersistenceManager {
    static let shared = PersistenceManager()
}
