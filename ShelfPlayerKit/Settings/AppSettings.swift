//
//  AppSettings.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import Observation
import OSLog

@Observable
public final class AppSettings: @unchecked Sendable {
    public static let shared = AppSettings()

    @ObservationIgnored private let suite: UserDefaults
    @ObservationIgnored private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "AppSettings")

    // MARK: - Settings

    public var removeFinishedDownloads = true {
        didSet { suite.set(removeFinishedDownloads, forKey: "removeFinishedDownloads") }
    }

    public var forceAspectRatio = false {
        didSet { suite.set(forceAspectRatio, forKey: "forceAspectRatio") }
    }

    public var groupAudiobooksInSeries = true {
        didSet { suite.set(groupAudiobooksInSeries, forKey: "groupAudiobooksInSeries") }
    }

    // MARK: Playback

    public var enableChapterTrack = true {
        didSet { suite.set(enableChapterTrack, forKey: "enableChapterTrack") }
    }

    public var enableSmartRewind = true {
        didSet { suite.set(enableSmartRewind, forKey: "enableSmartRewind") }
    }

    public var generateUpNextQueue = true {
        didSet { suite.set(generateUpNextQueue, forKey: "generateUpNextQueue") }
    }

    // MARK: Sleep Timer

    public var sleepTimerFadeOut = true {
        didSet { suite.set(sleepTimerFadeOut, forKey: "sleepTimerFadeOut") }
    }

    public var shakeExtendsSleepTimer = false {
        didSet { suite.set(shakeExtendsSleepTimer, forKey: "shakeExtendsSleepTimer") }
    }

    public var extendSleepTimerOnPlay = false {
        didSet { suite.set(extendSleepTimerOnPlay, forKey: "extendSleepTimerOnPlay") }
    }

    public var skipBackwardsInterval = 30 {
        didSet { suite.set(skipBackwardsInterval, forKey: "skipBackwardsInterval") }
    }

    public var skipForwardsInterval = 30 {
        didSet { suite.set(skipForwardsInterval, forKey: "skipForwardsInterval") }
    }

    public var remoteSeekAutoEndInterval: Double = 20.0 {
        didSet { suite.set(remoteSeekAutoEndInterval, forKey: "remoteSeekAutoEndInterval") }
    }

    // MARK: Advanced

    public var enableSerifFont = true {
        didSet { suite.set(enableSerifFont, forKey: "enableSerifFont") }
    }

    public var showSingleEntryGroupedSeries = true {
        didSet { suite.set(showSingleEntryGroupedSeries, forKey: "showSingleEntryGroupedSeries") }
    }

    public var itemImageStatusPercentageText = false {
        didSet { suite.set(itemImageStatusPercentageText, forKey: "itemImageStatusPercentageText") }
    }

    public var lockSeekBar = false {
        didSet { suite.set(lockSeekBar, forKey: "lockSeekBar") }
    }

    public var replaceVolumeWithTotalProgress = true {
        didSet { suite.set(replaceVolumeWithTotalProgress, forKey: "replaceVolumeWithTotalProgress") }
    }

    public var allowCellularDownloads = false {
        didSet { suite.set(allowCellularDownloads, forKey: "allowCellularDownloads") }
    }

    public var ultraHighQuality = false {
        didSet { suite.set(ultraHighQuality, forKey: "ultraHighQuality") }
    }

    // MARK: - In-App Settings

    public var playbackRates: [Double] = [0.9, 1, 1.3, 1.6, 2] {
        didSet { encodeCodable(playbackRates, forKey: "playbackRates") }
    }

    public var defaultPlaybackRate: Double = 1 {
        didSet { suite.set(defaultPlaybackRate, forKey: "defaultPlaybackRate") }
    }

    public var sleepTimerIntervals: [Double] = [5, 10, 15, 20, 25, 30, 45, 60, 75, 90].map { Double($0) * 60 } {
        didSet { encodeCodable(sleepTimerIntervals, forKey: "sleepTimerIntervals") }
    }

    public var sleepTimerExtendInterval: Double = 1200 {
        didSet { suite.set(sleepTimerExtendInterval, forKey: "sleepTimerExtendInterval") }
    }

    public var sleepTimerExtendChapterAmount = 1 {
        didSet { suite.set(sleepTimerExtendChapterAmount, forKey: "sleepTimerExtendChapterAmount") }
    }

    public var extendSleepTimerByPreviousSetting = true {
        didSet { suite.set(extendSleepTimerByPreviousSetting, forKey: "extendSleepTimerByPreviousSetting") }
    }

    public var tintColor: TintColor = .shelfPlayer {
        didSet { encodeCodable(tintColor, forKey: "tintColor") }
    }

    public var colorScheme: ConfiguredColorScheme = .system {
        didSet { suite.set(colorScheme.rawValue, forKey: "colorScheme") }
    }

    public var enableConvenienceDownloads = true {
        didSet { suite.set(enableConvenienceDownloads, forKey: "enableConvenienceDownloads") }
    }

    public var enableListenNowDownloads = false {
        didSet { suite.set(enableListenNowDownloads, forKey: "enableListenNowDownloads") }
    }

    public var listenTimeTarget = 30 {
        didSet { suite.set(listenTimeTarget, forKey: "listenTimeTarget") }
    }

    public var defaultEpisodeSortOrder: EpisodeSortOrder = .index {
        didSet { suite.set(defaultEpisodeSortOrder.rawValue, forKey: "defaultEpisodeSortOrder") }
    }

    public var defaultEpisodeAscending = true {
        didSet { suite.set(defaultEpisodeAscending, forKey: "defaultEpisodeAscending") }
    }

    // MARK: - Filtering & Sorting

    public var audiobooksAscending = false {
        didSet { suite.set(audiobooksAscending, forKey: "audiobooksAscending") }
    }

    public var audiobooksSortOrder: AudiobookSortOrder = .added {
        didSet { suite.set(audiobooksSortOrder.rawValue, forKey: "audiobookSortOrder") }
    }

    public var audiobooksFilter: ItemFilter = .all {
        didSet { suite.set(audiobooksFilter.rawValue, forKey: "audiobooksFilter") }
    }

    public var audiobooksRestrictToPersisted = false {
        didSet { suite.set(audiobooksRestrictToPersisted, forKey: "audiobooksRestrictToPersisted") }
    }

    public var audiobooksDisplayType: ItemDisplayType = .list {
        didSet { suite.set(audiobooksDisplayType.rawValue, forKey: "audiobooksDisplayType") }
    }

    public var authorsAscending = true {
        didSet { suite.set(authorsAscending, forKey: "authorsAscending") }
    }

    public var authorsSortOrder: AuthorSortOrder = .firstNameLastName {
        didSet { suite.set(authorsSortOrder.rawValue, forKey: "authorsSortOrder") }
    }

    public var narratorsAscending = true {
        didSet { suite.set(narratorsAscending, forKey: "narratorsAscending") }
    }

    public var narratorsSortOrder: NarratorSortOrder = .name {
        didSet { suite.set(narratorsSortOrder.rawValue, forKey: "narratorsSortOrder") }
    }

    public var seriesSortOrder: SeriesSortOrder = .sortName {
        didSet { suite.set(seriesSortOrder.rawValue, forKey: "seriesSortOrder") }
    }

    public var seriesAscending = true {
        didSet { suite.set(seriesAscending, forKey: "seriesAscending") }
    }

    public var seriesDisplayType: ItemDisplayType = .grid {
        didSet { suite.set(seriesDisplayType.rawValue, forKey: "seriesDisplayType") }
    }

    public var bookmarksAscending = true {
        didSet { suite.set(bookmarksAscending, forKey: "bookmarksAscending") }
    }

    public var bookmarksSortOrder: BookmarkSortOrder = .name {
        didSet { suite.set(bookmarksSortOrder.rawValue, forKey: "bookmarksSortOrder") }
    }

    public var genresAscending = true {
        didSet { suite.set(genresAscending, forKey: "genresAscending") }
    }

    public var tagsAscending = true {
        didSet { suite.set(tagsAscending, forKey: "tagsAscending") }
    }

    public var podcastsAscending = true {
        didSet { suite.set(podcastsAscending, forKey: "podcastsAscending") }
    }

    public var podcastsSortOrder: PodcastSortOrder = .name {
        didSet { suite.set(podcastsSortOrder.rawValue, forKey: "podcastsSortOrder") }
    }

    public var podcastsFilter: PodcastFilter = .all {
        didSet { suite.set(podcastsFilter.rawValue, forKey: "podcastsFilter") }
    }

    public var podcastsDisplayType: ItemDisplayType = .grid {
        didSet { suite.set(podcastsDisplayType.rawValue, forKey: "podcastsDisplayType") }
    }

    // MARK: - Playback

    public var lastPlayedItemID: ItemIdentifier? = nil {
        didSet { encodeCodable(lastPlayedItemID, forKey: "lastPlayedItemID") }
    }

    public var playbackResumeQueue: [ItemIdentifier] = [] {
        didSet { encodeCodable(playbackResumeQueue, forKey: "playbackResumeQueue") }
    }

    // MARK: - Widgets (shared suite)

    public var listenedTodayWidgetValue: ListenedTodayPayload? = nil {
        didSet { encodeCodable(listenedTodayWidgetValue, forKey: "listenedTodayWidgetValue") }
    }

    public var playbackInfoWidgetValue: PlaybackInfoPayload? = nil {
        didSet { encodeCodable(playbackInfoWidgetValue, forKey: "playbackInfoWidgetValue") }
    }

    // MARK: - Utility

    public var openPlaybackSessions: [OpenPlaybackSessionPayload] = [] {
        didSet { encodeCodable(openPlaybackSessions, forKey: "openPlaybackSessions") }
    }

    public var spotlightIndexCompletionDate: Date? = nil {
        didSet { suite.set(spotlightIndexCompletionDate, forKey: "spotlightIndexCompletionDate") }
    }

    public var lastConvenienceDownloadRun: Date? = nil {
        didSet { suite.set(lastConvenienceDownloadRun, forKey: "lastConvenienceDownloadRun") }
    }

    public var lastBuild: String? = nil {
        didSet { suite.set(lastBuild, forKey: "lastBuild") }
    }

    public var lastToSUpdate: Int? = nil {
        didSet { suite.set(lastToSUpdate, forKey: "lastToSUpdate") }
    }

    public var lastCheckedServerVersion: String? = nil {
        didSet { suite.set(lastCheckedServerVersion, forKey: "lastCheckedServerVersion") }
    }

    public var durationToggled = false {
        didSet { suite.set(durationToggled, forKey: "durationToggled") }
    }

    public var pinnedTabValues: [TabValue] = [] {
        didSet { encodeCodable(pinnedTabValues, forKey: "pinnedTabValues") }
    }

    public var isOffline = false {
        didSet { suite.set(isOffline, forKey: "isOffline") }
    }

    // MARK: - Multiplatform keys

    public var lastTabValue: TabValue? = nil {
        didSet { encodeCodable(lastTabValue, forKey: "lastTabValue") }
    }

    public var hiddenLibraries: Set<LibraryIdentifier> = [] {
        didSet { encodeCodable(hiddenLibraries, forKey: "hiddenLibraries") }
    }

    public var carPlayTabBarLibraries: [Library]? = nil {
        didSet { encodeCodable(carPlayTabBarLibraries, forKey: "carPlayTabBarLibraries") }
    }

    public var carPlayShowOtherLibraries = true {
        didSet { suite.set(carPlayShowOtherLibraries, forKey: "carPlayShowOtherLibraries") }
    }

    public var enableHapticFeedback = true {
        didSet { suite.set(enableHapticFeedback, forKey: "enableHapticFeedback") }
    }

    public var animatedNowPlayingBackground = true {
        didSet { suite.set(animatedNowPlayingBackground, forKey: "animatedNowPlayingBackground") }
    }

    // MARK: - Init

    private init() {
        suite = ShelfPlayerKit.enableCentralized
            ? (UserDefaults(suiteName: ShelfPlayerKit.groupContainer) ?? .standard)
            : .standard

        // Load persisted values (didSet does NOT fire during init)

        removeFinishedDownloads = suite.object(forKey: "removeFinishedDownloads") as? Bool ?? true
        forceAspectRatio = suite.object(forKey: "forceAspectRatio") as? Bool ?? false
        groupAudiobooksInSeries = suite.object(forKey: "groupAudiobooksInSeries") as? Bool ?? true

        enableChapterTrack = suite.object(forKey: "enableChapterTrack") as? Bool ?? true
        enableSmartRewind = suite.object(forKey: "enableSmartRewind") as? Bool ?? true
        generateUpNextQueue = suite.object(forKey: "generateUpNextQueue") as? Bool ?? true

        sleepTimerFadeOut = suite.object(forKey: "sleepTimerFadeOut") as? Bool ?? true
        shakeExtendsSleepTimer = suite.object(forKey: "shakeExtendsSleepTimer") as? Bool ?? false
        extendSleepTimerOnPlay = suite.object(forKey: "extendSleepTimerOnPlay") as? Bool ?? false
        skipBackwardsInterval = suite.object(forKey: "skipBackwardsInterval") as? Int ?? 30
        skipForwardsInterval = suite.object(forKey: "skipForwardsInterval") as? Int ?? 30
        remoteSeekAutoEndInterval = suite.object(forKey: "remoteSeekAutoEndInterval") as? Double ?? 20.0

        enableSerifFont = suite.object(forKey: "enableSerifFont") as? Bool ?? true
        showSingleEntryGroupedSeries = suite.object(forKey: "showSingleEntryGroupedSeries") as? Bool ?? true
        itemImageStatusPercentageText = suite.object(forKey: "itemImageStatusPercentageText") as? Bool ?? false
        lockSeekBar = suite.object(forKey: "lockSeekBar") as? Bool ?? false
        replaceVolumeWithTotalProgress = suite.object(forKey: "replaceVolumeWithTotalProgress") as? Bool ?? true
        allowCellularDownloads = suite.object(forKey: "allowCellularDownloads") as? Bool ?? false
        ultraHighQuality = suite.object(forKey: "ultraHighQuality") as? Bool ?? false

        if let val: [Double] = decodeCodable(forKey: "playbackRates") { playbackRates = val }
        defaultPlaybackRate = suite.object(forKey: "defaultPlaybackRate") as? Double ?? 1

        if let val: [Double] = decodeCodable(forKey: "sleepTimerIntervals") { sleepTimerIntervals = val }
        sleepTimerExtendInterval = suite.object(forKey: "sleepTimerExtendInterval") as? Double ?? 1200
        sleepTimerExtendChapterAmount = suite.object(forKey: "sleepTimerExtendChapterAmount") as? Int ?? 1
        extendSleepTimerByPreviousSetting = suite.object(forKey: "extendSleepTimerByPreviousSetting") as? Bool ?? true

        if let val: TintColor = decodeCodable(forKey: "tintColor") { tintColor = val }
        if let raw = suite.object(forKey: "colorScheme") as? Int,
           let val = ConfiguredColorScheme(rawValue: raw) { colorScheme = val }

        enableConvenienceDownloads = suite.object(forKey: "enableConvenienceDownloads") as? Bool ?? true
        enableListenNowDownloads = suite.object(forKey: "enableListenNowDownloads") as? Bool ?? false
        listenTimeTarget = suite.object(forKey: "listenTimeTarget") as? Int ?? 30

        if let raw = suite.object(forKey: "defaultEpisodeSortOrder") as? Int,
           let val = EpisodeSortOrder(rawValue: raw) { defaultEpisodeSortOrder = val }
        defaultEpisodeAscending = suite.object(forKey: "defaultEpisodeAscending") as? Bool ?? true

        audiobooksAscending = suite.object(forKey: "audiobooksAscending") as? Bool ?? false
        if let raw = suite.object(forKey: "audiobookSortOrder") as? String,
           let val = AudiobookSortOrder(rawValue: raw) { audiobooksSortOrder = val }
        if let raw = suite.object(forKey: "audiobooksFilter") as? Int,
           let val = ItemFilter(rawValue: raw) { audiobooksFilter = val }
        audiobooksRestrictToPersisted = suite.object(forKey: "audiobooksRestrictToPersisted") as? Bool ?? false
        if let raw = suite.object(forKey: "audiobooksDisplayType") as? Int,
           let val = ItemDisplayType(rawValue: raw) { audiobooksDisplayType = val }

        authorsAscending = suite.object(forKey: "authorsAscending") as? Bool ?? true
        if let raw = suite.object(forKey: "authorsSortOrder") as? Int,
           let val = AuthorSortOrder(rawValue: raw) { authorsSortOrder = val }

        narratorsAscending = suite.object(forKey: "narratorsAscending") as? Bool ?? true
        if let raw = suite.object(forKey: "narratorsSortOrder") as? Int,
           let val = NarratorSortOrder(rawValue: raw) { narratorsSortOrder = val }

        if let raw = suite.object(forKey: "seriesSortOrder") as? String,
           let val = SeriesSortOrder(rawValue: raw) { seriesSortOrder = val }
        seriesAscending = suite.object(forKey: "seriesAscending") as? Bool ?? true
        if let raw = suite.object(forKey: "seriesDisplayType") as? Int,
           let val = ItemDisplayType(rawValue: raw) { seriesDisplayType = val }

        bookmarksAscending = suite.object(forKey: "bookmarksAscending") as? Bool ?? true
        if let raw = suite.object(forKey: "bookmarksSortOrder") as? Int,
           let val = BookmarkSortOrder(rawValue: raw) { bookmarksSortOrder = val }

        genresAscending = suite.object(forKey: "genresAscending") as? Bool ?? true
        tagsAscending = suite.object(forKey: "tagsAscending") as? Bool ?? true

        podcastsAscending = suite.object(forKey: "podcastsAscending") as? Bool ?? true
        if let raw = suite.object(forKey: "podcastsSortOrder") as? Int,
           let val = PodcastSortOrder(rawValue: raw) { podcastsSortOrder = val }
        if let raw = suite.object(forKey: "podcastsFilter") as? Int,
           let val = PodcastFilter(rawValue: raw) { podcastsFilter = val }
        if let raw = suite.object(forKey: "podcastsDisplayType") as? Int,
           let val = ItemDisplayType(rawValue: raw) { podcastsDisplayType = val }

        lastPlayedItemID = decodeCodable(forKey: "lastPlayedItemID")
        if let val: [ItemIdentifier] = decodeCodable(forKey: "playbackResumeQueue") { playbackResumeQueue = val }

        listenedTodayWidgetValue = decodeCodable(forKey: "listenedTodayWidgetValue")
        playbackInfoWidgetValue = decodeCodable(forKey: "playbackInfoWidgetValue")

        if let val: [OpenPlaybackSessionPayload] = decodeCodable(forKey: "openPlaybackSessions") { openPlaybackSessions = val }
        spotlightIndexCompletionDate = suite.object(forKey: "spotlightIndexCompletionDate") as? Date
        lastConvenienceDownloadRun = suite.object(forKey: "lastConvenienceDownloadRun") as? Date
        lastBuild = suite.string(forKey: "lastBuild")
        lastToSUpdate = suite.object(forKey: "lastToSUpdate") as? Int
        lastCheckedServerVersion = suite.string(forKey: "lastCheckedServerVersion")
        durationToggled = suite.object(forKey: "durationToggled") as? Bool ?? false
        if let val: [TabValue] = decodeCodable(forKey: "pinnedTabValues") { pinnedTabValues = val }
        isOffline = suite.object(forKey: "isOffline") as? Bool ?? false

        lastTabValue = decodeCodable(forKey: "lastTabValue")
        if let val: Set<LibraryIdentifier> = decodeCodable(forKey: "hiddenLibraries") { hiddenLibraries = val }
        carPlayTabBarLibraries = decodeCodable(forKey: "carPlayTabBarLibraries")
        carPlayShowOtherLibraries = suite.object(forKey: "carPlayShowOtherLibraries") as? Bool ?? true
        enableHapticFeedback = suite.object(forKey: "enableHapticFeedback") as? Bool ?? true
        animatedNowPlayingBackground = suite.object(forKey: "animatedNowPlayingBackground") as? Bool ?? true
    }
}

// MARK: - JSON Encoding/Decoding Helpers

private extension AppSettings {
    func decodeCodable<T: Decodable>(forKey key: String) -> T? {
        guard let data = suite.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.warning("Failed to decode AppSettings value for key \(key, privacy: .public): \(error, privacy: .public)")
            return nil
        }
    }

    func encodeCodable<T: Encodable>(_ value: T?, forKey key: String) {
        guard let value else {
            suite.removeObject(forKey: key)
            return
        }

        do {
            let data = try JSONEncoder().encode(value)
            suite.set(data, forKey: key)
        } catch {
            logger.warning("Failed to encode AppSettings value for key \(key, privacy: .public): \(error, privacy: .public)")
        }
    }
}

// MARK: - Payload Types

public struct ListenedTodayPayload: Codable, Sendable {
    public var total: Int
    public var updated: Date

    public init(total: Int, updated: Date) {
        self.total = total
        self.updated = updated
    }
}

public enum ConfiguredColorScheme: Int, Codable, Sendable, CaseIterable, Hashable {
    case system
    case light
    case dark
}

public struct PlaybackInfoPayload: Codable, Sendable {
    public let currentItemID: ItemIdentifier?
    public let isPlaying: Bool?

    public init(currentItemID: ItemIdentifier?, isPlaying: Bool?) {
        self.currentItemID = currentItemID
        self.isPlaying = isPlaying
    }
}

public struct OpenPlaybackSessionPayload: Identifiable, Codable, Sendable {
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
