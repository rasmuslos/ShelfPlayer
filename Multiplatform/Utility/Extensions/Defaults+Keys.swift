//
//  Defaults+Keys.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import Foundation
import Defaults
import ShelfPlayerKit

internal extension Defaults.Keys {
    static let backgroundTaskFailCount = Key<Int>("backgroundTaskFailCount", default: 0)
    
    // MARK: Navigation
    
    static let sidebarSelection = Key<Sidebar.Selection?>("sidebarSelection")
    
    static let audiobookTab = Key<AudiobookTabs.Tab>("audiobookTab", default: .listenNow)
    static let podcastTab = Key<PodcastTabs.Tab>("podcastTab", default: .listenNow)
    
    // MARK: Settings
    
    static let sleepTimerAdjustment = Key<Double>("sleepTimerAdjustment", default: 60)
    static let playbackSpeedAdjustment = Key<Float>("playbackSpeedAdjustment", default: 0.25)
    
    static let customSleepTimer = Key<Int>("customSleepTimer", default: 0)
    static let customPlaybackSpeed = Key<Float>("customPlaybackSpeed", default: 1)
    
    static let defaultPlaybackSpeed = Key<Float>("defaultPlaybackSpeed", default: 1)
    
    static let useSerifFont = Key("useSerifFont", default: true)
    static let tintColor = Key<TintPicker.TintColor>("tintColor", default: .shelfPlayer)
    
    static let lockSeekBar = Key("lockSeekBar", default: false)
    static let siriOfflineMode = Key("siriOfflineMode", default: false)
    static let forceAspectRatio = Key("forceAspectRatio", default: false)
    static let itemImageStatusPercentageText = Key("itemImageStatusPercentageText", default: false)
    
    static let showAuthorsRow = Key("showAuthorsRow", default: false)
    static let authorsAscending = Key("authorsAscending", default: true)
    static let disableDiscoverRow = Key("disableDiscoverRow", default: false)
    
    static let podcastNextUp = Key("podcastNextUp", default: false)
    
    // MARK: Podcast filter & sort
    
    static func episodesFilter(podcastId: String) -> Defaults.Key<EpisodeFilter> {
        .init("episodesFilter-\(podcastId)", default: .unfinished)
    }
    
    static func episodesSort(podcastId: String) -> Defaults.Key<EpisodeSortOrder> {
        .init("episodesSort-\(podcastId)", default: .released)
    }
    static func episodesAscending(podcastId: String) -> Defaults.Key<Bool> {
        .init("episodesFilterAscending-\(podcastId)", default: false)
    }
}
