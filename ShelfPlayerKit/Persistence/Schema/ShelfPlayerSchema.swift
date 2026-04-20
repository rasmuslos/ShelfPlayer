//
//  ShelfPlayerSchema.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

public enum ShelfPlayerSchema: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {[
        PersistedAudiobook.self,
        PersistedEpisode.self,
        PersistedPodcast.self,

        PersistedAsset.self,
        PersistedBookmark.self,
        PersistedChapter.self,

        PersistedProgress.self,
        PersistedPlaybackSession.self,

        PersistedSearchIndexEntry.self,
        PersistedDiscoveredConnection.self,

        PersistedPlaybackRate.self,
        PersistedSleepTimerConfig.self,
        PersistedUpNextStrategy.self,
        PersistedDominantColor.self,
        PersistedPodcastFilterSort.self,
        PersistedTabCustomization.self,
        PersistedLibraryIndex.self,
        PersistedHomeCustomization.self,
    ]}
}
