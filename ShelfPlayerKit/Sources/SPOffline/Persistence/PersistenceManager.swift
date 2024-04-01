//
//  PersistenceManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import SwiftData
import SPBase

public struct PersistenceManager {
    public let modelContainer: ModelContainer = {
        let schema = Schema([
            OfflineTrack.self,
            OfflineChapter.self,
            ItemProgress.self,
            
            OfflineAudiobook.self,
            
            OfflinePodcast.self,
            OfflineEpisode.self,
            
            PodcastFetchConfiguration.self,
            PlaybackDuration.self,
        ], version: .init(1, 0, 1))
        
        let modelConfiguration = ModelConfiguration("ShelfPlayer", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: ENABLE_ALL_FEATURES ? .identifier("group.io.rfk.shelfplayer") : .none)
        
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
