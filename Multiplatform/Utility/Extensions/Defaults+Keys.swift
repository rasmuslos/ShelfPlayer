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
    
    static let lastTabValue = Key<TabValue?>("lastTabValue")
    
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
    static let disableDiscoverRow = Key("disableDiscoverRow", default: false)
    
    static let shakeExtendsSleepTimer = Key("shakeExtendsSleepTimer", default: true)
    
    // MARK: Filter & sort utility
    
    static let audiobooksSortOrder = Key<AudiobookSortOrder>("audiobooksSortOrder", default: .added)
    static let audiobooksAscending = Key<Bool>("audiobooksFilterAscending", default: true)
    
    static let audiobooksFilter = Key<ItemFilter>("audiobooksFilter", default: .all)
    static let audiobooksDisplay = Key<ItemDisplayType>("audiobooksDisplay", default: .list)
    
    static let seriesDisplayType = Key<ItemDisplayType>("seriesDisplay", default: .grid)
    
    static let authorsAscending = Key("authorsAscending", default: true)
    static let podcastsAscending = Key("podcastsAscending", default: true)
    
    static func episodesFilter(podcastId: String) -> Defaults.Key<ItemFilter> {
        .init("episodesFilter-\(podcastId)", default: .unfinished)
    }
    
    static func episodesSortOrder(podcastId: String) -> Defaults.Key<EpisodeSortOrder> {
        .init("episodesSort-\(podcastId)", default: .released)
    }
    static func episodesAscending(podcastId: String) -> Defaults.Key<Bool> {
        .init("episodesFilterAscending-\(podcastId)", default: false)
    }
    
    // MARK: Intents
    
    static let lastSpotlightIndex = Key<Date?>("lastSpotlightIndex", default: nil)
    static let indexedIdentifiers = Key<[String]>("indexedIdentifiers", default: [])
}
