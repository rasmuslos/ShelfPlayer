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
    static let lastCarPlayTabValue = Key<String?>("lastCarPlayTabValue")
    
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
    
    static let collapseSeries = Key("collapseSeries", default: true)
    
    // MARK: Filter & sort utility
    
    static let audiobooksSortOrder = Key<AudiobookSortOrder>("audiobookSortOrder", default: .authorName)
    static let audiobooksAscending = Key<Bool>("audiobooksAscending", default: true)
    
    static let offlineAudiobooksAscending = Key<Bool>("offlineAudiobooksAscending", default: true)
    static let offlineAudiobooksSortOrder = Key<AudiobookSortOrder>("offlineAudiobooksSortOrder", default: .lastPlayed)
    
    static let audiobooksFilter = Key<ItemFilter>("audiobooksFilter", default: .all)
    static let audiobooksDisplay = Key<ItemDisplayType>("audiobooksDisplay", default: .list)
    
    static let seriesDisplayType = Key<ItemDisplayType>("seriesDisplay", default: .grid)
    static let podcastsDisplayType = Key<ItemDisplayType>("podcastsDisplay", default: .grid)
    
    static let authorsAscending = Key("authorsAscending", default: true)
    static let podcastsAscending = Key("podcastsAscending", default: true)
    
    // MARK: Intents
    
    static let lastSpotlightIndex = Key<Date?>("lastSpotlightIndex", default: nil)
    static let indexedIdentifiers = Key<[String]>("indexedIdentifiers", default: [])
}
