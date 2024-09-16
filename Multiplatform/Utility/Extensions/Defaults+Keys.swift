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
    
    static let lastActiveLibraryID = Key<String?>("lastActiveLibraryID")
    
    static let sidebarSelection = Key<Sidebar.Selection?>("sidebarSelection")
    
    static let audiobookTab = Key<AudiobookTabs.Tab>("audiobookTab", default: .listenNow)
    static let podcastTab = Key<PodcastTabs.Tab>("podcastTab", default: .listenNow)
    
    // MARK: Settings
    
    static let sleepTimerAdjustment = Key<TimeInterval>("sleepTimerAdjustment", default: 60)
    static let playbackSpeedAdjustment = Key<Percentage>("playbackSpeedAdjustment", default: 0.25)
    
    static let customSleepTimer = Key<Int>("customSleepTimer", default: 0)
    static let customPlaybackSpeed = Key<Percentage>("customPlaybackSpeed", default: 1)
    
    static let defaultPlaybackSpeed = Key<Percentage>("defaultPlaybackSpeed", default: 1)
    
    static let useSerifFont = Key("useSerifFont", default: true)
    static let tintColor = Key<TintPicker.TintColor>("tintColor", default: .shelfPlayer)
    
    static let lockSeekBar = Key("lockSeekBar", default: false)
    static let forceAspectRatio = Key("forceAspectRatio", default: false)
    static let itemImageStatusPercentageText = Key("itemImageStatusPercentageText", default: false)
    
    static let showAuthorsRow = Key("showAuthorsRow", default: false)
    static let authorsAscending = Key("authorsAscending", default: true)
    static let disableDiscoverRow = Key("disableDiscoverRow", default: false)
    
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
    
    // MARK: Filter & sort utility
    
    static let audiobooksDisplay = Key<AudiobookSortFilter.DisplayType>("audiobooksDisplay", default: .list)
    static let audiobooksSortOrder = Key<AudiobookSortFilter.SortOrder>("audiobooksSortOrder", default: .added)
    
    static let audiobooksFilter = Key<AudiobookSortFilter.Filter>("audiobooksFilter", default: .all)
    static let audiobooksAscending = Key<Bool>("audiobooksFilterAscending", default: true)
    
    static let seriesDisplay = Key<AudiobookSortFilter.DisplayType>("seriesDisplay", default: .grid)
}
