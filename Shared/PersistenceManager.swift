//
//  PersistenceManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import SwiftData

struct PersistenceManager {
    let modelContainer: ModelContainer = {
        let schema = Schema([
            OfflineProgress.self,
            OfflineChapter.self,
            
            DownloadReference.self,
            
            OfflineAudiobook.self,
            OfflineAudiobookTrack.self,
            
            OfflineEpisode.self,
            OfflinePodcast.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
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
