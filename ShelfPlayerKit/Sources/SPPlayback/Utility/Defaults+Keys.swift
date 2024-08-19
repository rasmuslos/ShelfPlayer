//
//  Defaults.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import Defaults
import SPFoundation

public extension Defaults.Keys {
    static let skipForwardsInterval = Key<Int>("skipForwardsInterval", default: 30)
    static let skipBackwardsInterval = Key<Int>("skipBackwardsInterval", default: 30)
    
    static let lockSeekBar = Key<Bool>("lockSeekBar", default: false)
    static let enableChapterTrack = Key<Bool>("enableChapterTrack", default: true)
    
    static let smartRewind = Key<Bool>("smartRewind", default: false)
    static let deleteFinishedDownloads = Key<Bool>("deleteFinishedDownloads", default: false)
    
    static let defaultPlaybackSpeed = Key<Float>("defaultPlaybackSpeed", default: 1)
    static func playbackSpeed(itemId: String, episodeId: String?) -> Key<Float?> {
        .init("playbackSpeed_\(itemId)_\(episodeId ?? "Rasmus_was_here")", default: nil)
    }
    
    static let podcastNextUp = Key("podcastNextUp", default: false)
    
    static func episodesFilter(podcastId: String) -> Defaults.Key<AudiobookshelfClient.EpisodeFilter> {
        .init("episodesFilter-\(podcastId)", default: .unfinished)
    }
    
    static func episodesSort(podcastId: String) -> Defaults.Key<AudiobookshelfClient.EpisodeSortOrder> {
        .init("episodesSort-\(podcastId)", default: .released)
    }
    static func episodesAscending(podcastId: String) -> Defaults.Key<Bool> {
        .init("episodesFilterAscending-\(podcastId)", default: false)
    }
}
