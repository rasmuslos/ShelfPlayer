//
//  Defaults+Keys.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 29.10.24.
//

import Foundation
import Defaults

public extension Defaults.Keys {
    // MARK: Settings
    
    static let removeFinishedDownloads = Key("removeFinishedDownloads", default: true)
    static let forceAspectRatio = Key("forceAspectRatio", default: false)
    static let groupAudiobooksInSeries = Key("groupAudiobooksInSeries", default: true)
    
    // HOME
    
    static let showAuthorsRow = Key("showAuthorsRow", default: false)
    static let hideDiscoverRow = Key("hideDiscoverRow", default: false)
    
    // Playback
    
    static let enableChapterTrack = Key("enableChapterTrack", default: true)
    static let enableSmartRewind = Key("enableSmartRewind", default: true)
    
    // Sleep timer
    
    static let sleepTimerFadeOut = Key("sleepTimerFadeOut", default: true)
    static let shakeExtendsSleepTimer = Key("shakeExtendsSleepTimer", default: false)
    static let extendSleepTimerOnPlay = Key("extendSleepTimerOnPlay", default: false)
    
    static let skipBackwardsInterval = Key("skipBackwardsInterval", default: 30)
    static let skipForwardsInterval = Key("skipForwardsInterval", default: 30)
    
    static let queueNextEpisodes = Key("queueNextEpisodes", default: true)
    static let queueNextAudiobooksInSeries = Key("queueNextAudiobooksInSeries", default: false)
    
    // Advanced
    
    static let enableSerifFont = Key("enableSerifFont", default: true)
    static let itemImageStatusPercentageText = Key("itemImageStatusPercentageText", default: false)
    
    static let lockSeekBar = Key("lockSeekBar", default: false)
    static let replaceVolumeWithTotalProgress = Key("replaceVolumeWithTotalProgress", default: false)
    
    static let startInOfflineMode = Key("startInOfflineMode", default: false)
    
    // MARK: In-App settings
    // TODO: hhh
    
    static let playbackRates = Key<[Percentage]>("playbackRates", default: [0.5, 0.75, 1, 1.25, 1.5, 2])
    static let defaultPlaybackRate = Key<Percentage>("defaultPlaybackRate", default: 1)
    
    static let sleepTimerIntervals = Key("sleepTimerIntervals", default: [10, 20, 30, 45, 60, 90].map { Double($0) * 60 })
    static let sleepTimerExtendInterval = Key("sleepTimerExtendInterval", default: Double(1200))
    static let sleepTimerExtendChapterAmount = Key("sleepTimerExtendChapterAmount", default: 1)
    
    // MARK: Filtering & Sorting
    
    static let audiobooksAscending = Key<Bool>("audiobooksAscending", default: true, iCloud: true)
    static let audiobooksSortOrder = Key<AudiobookSortOrder>("audiobookSortOrder", default: .lastPlayed, iCloud: true)
    static let audiobooksFilter = Key<ItemFilter>("audiobooksFilter", default: .all, iCloud: true)
    static let audiobooksDisplayType = Key<ItemDisplayType>("audiobooksDisplayType", default: .list, iCloud: true)
    
    static let authorsAscending = Key("authorsAscending", default: true)
    static let authorsSortOrder = Key<AuthorSortOrder>("authorsSortOrder", default: .firstNameLastName, iCloud: true)
    
    static let seriesSortOrder = Key<SeriesSortOrder>("seriesSortOrder", default: .sortName, iCloud: true)
    static let seriesAscending = Key<Bool>("seriesAscending", default: true, iCloud: true)
    static let seriesDisplayType = Key<ItemDisplayType>("seriesDisplayType", default: .grid, iCloud: true)
    
    static func episodesAscending(_ itemID: ItemIdentifier) -> Defaults.Key<Bool> {
        .init("episodes-ascending-\(itemID.groupingID ?? itemID.primaryID)", default: false)
    }
    static func episodesSortOrder(_ itemID: ItemIdentifier) -> Defaults.Key<EpisodeSortOrder> {
        .init("episodes-sort-\(itemID.groupingID ?? itemID.primaryID)", default: .released)
    }
    static func episodesFilter(_ itemID: ItemIdentifier) -> Defaults.Key<ItemFilter> {
        .init("episodes-filter-\(itemID.groupingID ?? itemID.primaryID)", default: .notFinished)
    }
    static func episodesSeasonFilter(_ itemID: ItemIdentifier) -> Defaults.Key<String?> {
        .init("episodes-season-filter-\(itemID.groupingID ?? itemID.primaryID)", default: nil)
    }
    
    static let podcastsAscending = Key("podcastsAscending", default: true, iCloud: true)
    static let podcastsSortOrder = Key<PodcastSortOrder>("podcastsSortOrder", default: .name, iCloud: true)
    static let podcastsDisplayType = Key<ItemDisplayType>("podcastsDisplayType", default: .grid, iCloud: true)
    
    // MARK: Playback
    
    static let playbackResumeInfo = Key<PlaybackResumeInfo?>("playbackResumeInfo", default: nil)
}

public struct PlaybackResumeInfo: Codable, Sendable, Defaults.Serializable {
    public let itemID: ItemIdentifier
    public let started: Date
    
    public init(itemID: ItemIdentifier, started: Date) {
        self.itemID = itemID
        self.started = started
    }
}
