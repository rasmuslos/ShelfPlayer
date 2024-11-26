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
        let schema = Schema(versionedSchema: SchemaV1.self)
        let modelConfiguration = ModelConfiguration("ShelfPlayer",
                                                    schema: schema,
                                                    isStoredInMemoryOnly: false,
                                                    allowsSave: true,
                                                    groupContainer: SPKit_ENABLE_ALL_FEATURES ? .identifier("group.io.rfk.shelfplayer") : .none)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

public typealias OfflineTrack = SchemaV1.OfflineTrack
public typealias OfflineChapter = SchemaV1.OfflineChapter

public typealias Bookmark = SchemaV1.Bookmark
internal typealias OfflineProgress = SchemaV1.OfflineProgress

public typealias OfflineAudiobook = SchemaV1.OfflineAudiobook

public typealias OfflinePodcast = SchemaV1.OfflinePodcast
public typealias OfflineEpisode = SchemaV1.OfflineEpisode

public typealias PlaybackSpeedOverride = SchemaV1.PlaybackSpeedOverride
public typealias PodcastFetchConfiguration = SchemaV1.PodcastFetchConfiguration
public typealias OfflineListeningTimeTracker = SchemaV1.OfflineListeningTimeTracker

// MARK: Singleton

public extension PersistenceManager {
    static let shared = PersistenceManager()
}
