//
//  Defaults+Keys.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 29.10.24.
//

import Foundation
import RFNotifications

public extension UserDefaults {
    nonisolated(unsafe) static let shared = {
        if ShelfPlayerKit.enableCentralized {
            UserDefaults(suiteName: ShelfPlayerKit.groupContainer)!
        } else {
            UserDefaults.standard
        }
    }()
}

// MARK: Defaults

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
    static let generateUpNextQueue = Key("generateUpNextQueue", default: true)
    
    // Sleep timer
    
    static let sleepTimerFadeOut = Key("sleepTimerFadeOut", default: true)
    static let shakeExtendsSleepTimer = Key("shakeExtendsSleepTimer", default: false)
    static let extendSleepTimerOnPlay = Key("extendSleepTimerOnPlay", default: false)
    
    static let skipBackwardsInterval = Key("skipBackwardsInterval", default: 30)
    static let skipForwardsInterval = Key("skipForwardsInterval", default: 30)
    
    // Advanced
    
    static let enableSerifFont = Key("enableSerifFont", default: true)
    static let showSingleEntryGroupedSeries = Key("showSingleEntryGroupedSeries", default: true)
    static let itemImageStatusPercentageText = Key("itemImageStatusPercentageText", default: false)
    
    static let lockSeekBar = Key("lockSeekBar", default: false)
    static let replaceVolumeWithTotalProgress = Key("replaceVolumeWithTotalProgress", default: false)
    
    static let allowCellularDownloads = Key("allowCellularDownloads", default: false)
    
    static let startInOfflineMode = Key("startInOfflineMode", default: false)
    
    // MARK: In-App settings
    
    static let playbackRates = Key<[Percentage]>("playbackRates", default: [0.5, 0.75, 1, 1.25, 1.5, 2])
    static let defaultPlaybackRate = Key<Percentage>("defaultPlaybackRate", default: 1)
    
    static let sleepTimerIntervals = Key("sleepTimerIntervals", default: [10, 20, 30, 45, 60, 90].map { Double($0) * 60 })
    static let sleepTimerExtendInterval = Key("sleepTimerExtendInterval", default: Double(1200))
    static let sleepTimerExtendChapterAmount = Key("sleepTimerExtendChapterAmount", default: 1)
    
    static let extendSleepTimerByPreviousSetting = Key("extendSleepTimerByPreviousSetting", default: true)
    
    static let tintColor = Key("tintColor", default: TintColor.shelfPlayer, suite: .shared)
    
    static let enableConvenienceDownloads = Key("enableConvenienceDownloads", default: true)
    static let enableListenNowDownloads = Key("enableListenNowDownloads", default: false)
    
    static let listenTimeTarget = Key<Int>("listenTimeTarget", default: 30, suite: .shared)
    
    static let defaultEpisodeSortOrder = Key("defaultEpisodeSortOrder", default: EpisodeSortOrder.index, suite: .shared)
    static let defaultEpisodeAscending = Key("defaultEpisodeAscending", default: true, suite: .shared)
    
    // MARK: Filtering & Sorting
    
    static let audiobooksAscending = Key<Bool>("audiobooksAscending", default: false, iCloud: true)
    static let audiobooksSortOrder = Key<AudiobookSortOrder>("audiobookSortOrder", default: .added, iCloud: true)
    static let audiobooksFilter = Key<ItemFilter>("audiobooksFilter", default: .all, iCloud: true)
    static let audiobooksRestrictToPersisted = Key("audiobooksRestrictToPersisted", default: false, iCloud: true)
    static let audiobooksDisplayType = Key<ItemDisplayType>("audiobooksDisplayType", default: .list, iCloud: true)
    
    static let authorsAscending = Key("authorsAscending", default: true)
    static let authorsSortOrder = Key<AuthorSortOrder>("authorsSortOrder", default: .firstNameLastName, iCloud: true)
    
    static let narratorsAscending = Key("narratorsAscending", default: true)
    static let narratorsSortOrder = Key<NarratorSortOrder>("narratorsSortOrder", default: .name, iCloud: true)
    
    static let seriesSortOrder = Key<SeriesSortOrder>("seriesSortOrder", default: .sortName, iCloud: true)
    static let seriesAscending = Key<Bool>("seriesAscending", default: true, iCloud: true)
    static let seriesDisplayType = Key<ItemDisplayType>("seriesDisplayType", default: .grid, iCloud: true)
    
    static let podcastsAscending = Key("podcastsAscending", default: true, iCloud: true)
    static let podcastsSortOrder = Key<PodcastSortOrder>("podcastsSortOrder", default: .name, iCloud: true)
    static let podcastsDisplayType = Key<ItemDisplayType>("podcastsDisplayType", default: .grid, iCloud: true)
    
    // MARK: Playback
    
    static let playbackResumeInfo = Key<PlaybackResumeInfo?>("playbackResumeInfo", default: nil)
    static let playbackResumeQueue = Key<[ItemIdentifier]>("playbackResumeQueue", default: [])
    
    // MARK: Widgets
    
    static let listenedTodayWidgetValue = Key<ListenedTodayPayload?>("listenedTodayWidgetValue", default: nil, suite: .shared)
    static let playbackInfoWidgetValue = Key<PlaybackInfoPayload?>("playbackInfoWidgetValue", default: nil, suite: .shared)
    
    // MARK: Utility
    
    static let openPlaybackSessions = Key<[OpenPlaybackSessionPayload]>("openPlaybackSessions", default: [])
    static let spotlightIndexCompletionDate = Key<Date?>("spotlightIndexCompletionDate", default: nil)
    
    static let lastConvenienceDownloadRun = Key<Date?>("lastConvenienceDownloadRun", default: nil)
}

public struct PlaybackResumeInfo: Codable, Sendable, Defaults.Serializable {
    public let itemID: ItemIdentifier
    public let started: Date
    
    public init(itemID: ItemIdentifier, started: Date) {
        self.itemID = itemID
        self.started = started
    }
}

public struct ListenedTodayPayload: Codable, Defaults.Serializable {
    public var total: Int
    public var updated: Date
    
    public init(total: Int, updated: Date) {
        self.total = total
        self.updated = updated
    }
}

public struct PlaybackInfoPayload: Codable, Defaults.Serializable {
    public let currentItemID: ItemIdentifier?
    
    public let isDownloaded: Bool
    public let isPlaying: Bool?
    
    public let listenNowItems: [PlayableItem]
    
    public init(currentItemID: ItemIdentifier?, isDownloaded: Bool, isPlaying: Bool?, listenNowItems: [PlayableItem]) {
        self.currentItemID = currentItemID
        self.isDownloaded = isDownloaded
        self.isPlaying = isPlaying
        self.listenNowItems = listenNowItems
    }
}

public struct OpenPlaybackSessionPayload: Identifiable, Codable, Defaults.Serializable {
    public let sessionID: String
    public let itemID: ItemIdentifier
    
    public init(sessionID: String, itemID: ItemIdentifier) {
        self.sessionID = sessionID
        self.itemID = itemID
    }
    
    public var id: String {
        "\(itemID)-\(sessionID)"
    }
}

// MARK: Notifications

public extension RFNotification.NonIsolatedNotification {
    static var shake: NonIsolatedNotification<TimeInterval> { .init("io.rfk.shelfPlayer.shake") }
    static var finalizePlaybackReporting: NonIsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.finalizePlaybackReporting") }
}

public extension RFNotification.IsolatedNotification {
    // MARK: Authorization
    
    static var connectionsChanged: IsolatedNotification<[ItemIdentifier.ConnectionID: Connection]> {
        .init("io.rfk.shelfPlayerKit.connectionsChanged")
    }
    static var removeConnection: IsolatedNotification<ItemIdentifier.ConnectionID> {
        .init("io.rfk.shelfPlayerKit.removeConnection")
    }
    
    // MARK: Progress
    
    static var progressEntityUpdated: IsolatedNotification<(connectionID: String, primaryID: String, groupingID: String?, ProgressEntity?)> {
        .init("io.rfk.shelfPlayerKit.progressEntity.updated")
    }
    static var invalidateProgressEntities: IsolatedNotification<String?> {
        .init("io.rfk.shelfPlayerKit.progressEntity.invalidate")
    }
    
    // MARK: Download
    
    static var downloadStatusChanged: IsolatedNotification<(itemID: ItemIdentifier, status: DownloadStatus)?> {
        .init("io.rfk.shelfPlayerKit.downloadStatus.updated")
    }
    static func downloadProgressChanged(_ itemID: ItemIdentifier) -> IsolatedNotification<(assetID: UUID, weight: Percentage, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)> {
        .init("io.rfk.shelfPlayerKit.progress.updated_\(itemID.description)")
    }
    
    static var convenienceDownloadIteration: IsolatedNotification<RFNotificationEmptyPayload> {
        .init("io.rfk.shelfPlayerKit.convenienceDownloadIteration")
    }
    static var convenienceDownloadConfigurationsChanged: IsolatedNotification<RFNotificationEmptyPayload> {
        .init("io.rfk.shelfPlayerKit.convenienceDownloadConfigurationsChanged")
    }
    
    // MARK: Bookmarks
    
    static var bookmarksChanged: IsolatedNotification<ItemIdentifier> {
        .init("io.rfk.shelfPlayerKit.bookmarksChanged")
    }
    
    // MARK: Playback
    
    static var playbackItemChanged: IsolatedNotification<(ItemIdentifier, [Chapter], TimeInterval)> { .init("io.rfk.shelfPlayerKit.playbackItemChanged") }
    static var playStateChanged: IsolatedNotification<(Bool)> { .init("io.rfk.shelfPlayerKit.playStateChanged") }
    
    static var skipped: IsolatedNotification<(Bool)> { .init("io.rfk.shelfPlayerKit.skipped") }
    
    static var bufferHealthChanged: IsolatedNotification<(Bool)> { .init("io.rfk.shelfPlayerKit.bufferHealthChanged") }
    
    static var durationsChanged: IsolatedNotification<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?)> { .init("io.rfk.shelfPlayerKit.durationsChanged") }
    static var currentTimesChanged: IsolatedNotification<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?)> { .init("io.rfk.shelfPlayerKit.currentTimesChanged") }
    
    static var chapterChanged: IsolatedNotification<Chapter?> { .init("io.rfk.shelfPlayerKit.chapterChanged") }
    
    static var volumeChanged: IsolatedNotification<Percentage> { .init("io.rfk.shelfPlayerKit.volumeChanged") }
    static var playbackRateChanged: IsolatedNotification<Percentage> { .init("io.rfk.shelfPlayerKit.playbackRateChanged") }
    
    static var queueChanged: IsolatedNotification<[ItemIdentifier]> { .init("io.rfk.shelfPlayerKit.queueChanged") }
    static var upNextQueueChanged: IsolatedNotification<[ItemIdentifier]> { .init("io.rfk.shelfPlayerKit.upNextQueueChanged") }
    static var upNextStrategyChanged: IsolatedNotification<ResolvedUpNextStrategy?> { .init("io.rfk.shelfPlayerKit.upNextStrategyChanged") }
    
    static var playbackStopped: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.playbackStopped") }
    
    // MARK: Utility
    
    static var navigate: IsolatedNotification<ItemIdentifier> { .init("io.rfk.shelfPlayer.navigate.one") }
    
    static var reloadImages: IsolatedNotification<ItemIdentifier?> { .init("io.rfk.shelfPlayer.reloadImages") }
    static var listenNowItemsChanged: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.listenNowItemsChanged") }
    static var synchronizedPlaybackSessions: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.synchronizedPlaybackSessions") }
    
    // Sessions
    
    static var timeSpendListeningChanged: IsolatedNotification<Int> { .init("io.rfk.shelfPlayerKit.timeSpendListeningChanged") }
    static var cachedTimeSpendListeningChanged: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.cachedTimeSpendListeningChanged") }
}

