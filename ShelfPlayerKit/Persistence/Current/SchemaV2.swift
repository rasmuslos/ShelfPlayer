//
//  SchemaV2.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(2, 0, 0)
    }
    static var models: [any PersistentModel.Type] {[
        PersistedAudiobook.self,
        PersistedEpisode.self,
        PersistedPodcast.self,
         
        PersistedAsset.self,
        PersistedBookmark.self,
        PersistedChapter.self,
        
        PersistedProgress.self,
        PersistedPlaybackSession.self,
        
        PersistedKeyValueEntity.self,
        PersistedSearchIndexEntry.self,
        
        PersistedDiscoveredConnection.self,
    ]}
}
