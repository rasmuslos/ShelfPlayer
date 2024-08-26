//
//  PersistenceManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import SwiftData
import SPFoundation

public struct PersistenceManager {
    public let modelContainer: ModelContainer = {
        let schema = Schema([
            OfflineTrack.self,
            OfflineChapter.self,
            
            Bookmark.self,
            ItemProgress.self,
            
            OfflineAudiobook.self,
            
            OfflinePodcast.self,
            OfflineEpisode.self,
            
            PlaybackSpeedOverride.self,
            PodcastFetchConfiguration.self,
            OfflineListeningTimeTracker.self,
        ], version: .init(1, 1, 0))
        
        let modelConfiguration = ModelConfiguration("ShelfPlayer", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: SPKit_ENABLE_ALL_FEATURES ? .identifier("group.io.rfk.shelfplayer") : .none)
        
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
