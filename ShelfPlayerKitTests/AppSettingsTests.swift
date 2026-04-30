//
//  AppSettingsTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

/// Tests the public surface of `AppSettings`. The singleton is hard-wired to
/// `UserDefaults.standard` (or the app group, when centralized), so each test
/// snapshots the affected values up-front and restores them afterwards in a
/// `defer` block to avoid leaking state across runs.
@MainActor
struct AppSettingsTests {
    let settings = AppSettings.shared

    // MARK: - Bool round-trips

    @Test func removeFinishedDownloadsRoundTrip() {
        let original = settings.removeFinishedDownloads
        defer { settings.removeFinishedDownloads = original }

        settings.removeFinishedDownloads = true
        #expect(settings.removeFinishedDownloads == true)

        settings.removeFinishedDownloads = false
        #expect(settings.removeFinishedDownloads == false)
    }

    @Test func forceAspectRatioRoundTrip() {
        let original = settings.forceAspectRatio
        defer { settings.forceAspectRatio = original }

        settings.forceAspectRatio = true
        #expect(settings.forceAspectRatio == true)
        settings.forceAspectRatio = false
        #expect(settings.forceAspectRatio == false)
    }

    @Test func groupAudiobooksInSeriesRoundTrip() {
        let original = settings.groupAudiobooksInSeries
        defer { settings.groupAudiobooksInSeries = original }

        settings.groupAudiobooksInSeries = false
        #expect(settings.groupAudiobooksInSeries == false)
        settings.groupAudiobooksInSeries = true
        #expect(settings.groupAudiobooksInSeries == true)
    }

    @Test func playbackBoolToggles() {
        let originals = (
            chapterTrack: settings.enableChapterTrack,
            smartRewind: settings.enableSmartRewind,
            upNext: settings.generateUpNextQueue
        )
        defer {
            settings.enableChapterTrack = originals.chapterTrack
            settings.enableSmartRewind = originals.smartRewind
            settings.generateUpNextQueue = originals.upNext
        }

        settings.enableChapterTrack.toggle()
        settings.enableSmartRewind.toggle()
        settings.generateUpNextQueue.toggle()

        #expect(settings.enableChapterTrack == !originals.chapterTrack)
        #expect(settings.enableSmartRewind == !originals.smartRewind)
        #expect(settings.generateUpNextQueue == !originals.upNext)
    }

    @Test func sleepTimerBoolToggles() {
        let originals = (
            fadeOut: settings.sleepTimerFadeOut,
            shake: settings.shakeExtendsSleepTimer,
            extendOnPlay: settings.extendSleepTimerOnPlay
        )
        defer {
            settings.sleepTimerFadeOut = originals.fadeOut
            settings.shakeExtendsSleepTimer = originals.shake
            settings.extendSleepTimerOnPlay = originals.extendOnPlay
        }

        settings.sleepTimerFadeOut.toggle()
        settings.shakeExtendsSleepTimer.toggle()
        settings.extendSleepTimerOnPlay.toggle()

        #expect(settings.sleepTimerFadeOut == !originals.fadeOut)
        #expect(settings.shakeExtendsSleepTimer == !originals.shake)
        #expect(settings.extendSleepTimerOnPlay == !originals.extendOnPlay)
    }

    // MARK: - Numeric round-trips

    @Test func skipIntervalsRoundTrip() {
        let originalBack = settings.skipBackwardsInterval
        let originalForward = settings.skipForwardsInterval
        defer {
            settings.skipBackwardsInterval = originalBack
            settings.skipForwardsInterval = originalForward
        }

        settings.skipBackwardsInterval = 7
        settings.skipForwardsInterval = 12
        #expect(settings.skipBackwardsInterval == 7)
        #expect(settings.skipForwardsInterval == 12)
    }

    @Test func remoteSeekAutoEndIntervalRoundTrip() {
        let original = settings.remoteSeekAutoEndInterval
        defer { settings.remoteSeekAutoEndInterval = original }

        settings.remoteSeekAutoEndInterval = 33.5
        #expect(settings.remoteSeekAutoEndInterval == 33.5)
    }

    @Test func defaultPlaybackRateRoundTrip() {
        let original = settings.defaultPlaybackRate
        defer { settings.defaultPlaybackRate = original }

        settings.defaultPlaybackRate = 1.75
        #expect(settings.defaultPlaybackRate == 1.75)
    }

    @Test func sleepTimerExtendsRoundTrip() {
        let originalInterval = settings.sleepTimerExtendInterval
        let originalChapters = settings.sleepTimerExtendChapterAmount
        let originalByPrev = settings.extendSleepTimerByPreviousSetting
        defer {
            settings.sleepTimerExtendInterval = originalInterval
            settings.sleepTimerExtendChapterAmount = originalChapters
            settings.extendSleepTimerByPreviousSetting = originalByPrev
        }

        settings.sleepTimerExtendInterval = 555
        settings.sleepTimerExtendChapterAmount = 4
        settings.extendSleepTimerByPreviousSetting = false

        #expect(settings.sleepTimerExtendInterval == 555)
        #expect(settings.sleepTimerExtendChapterAmount == 4)
        #expect(settings.extendSleepTimerByPreviousSetting == false)
    }

    @Test func listenTimeTargetRoundTrip() {
        let original = settings.listenTimeTarget
        defer { settings.listenTimeTarget = original }

        settings.listenTimeTarget = 60
        #expect(settings.listenTimeTarget == 60)
    }

    // MARK: - Codable arrays

    @Test func playbackRatesRoundTrip() {
        let original = settings.playbackRates
        defer { settings.playbackRates = original }

        let custom = [0.5, 1.0, 1.25, 2.5]
        settings.playbackRates = custom
        #expect(settings.playbackRates == custom)
    }

    @Test func sleepTimerIntervalsRoundTrip() {
        let original = settings.sleepTimerIntervals
        defer { settings.sleepTimerIntervals = original }

        let custom: [Double] = [60, 120, 300]
        settings.sleepTimerIntervals = custom
        #expect(settings.sleepTimerIntervals == custom)
    }

    // MARK: - Enum round-trips

    @Test func tintColorRoundTrip() {
        let original = settings.tintColor
        defer { settings.tintColor = original }

        settings.tintColor = .blue
        #expect(settings.tintColor == .blue)
        settings.tintColor = .yellow
        #expect(settings.tintColor == .yellow)
    }

    @Test func colorSchemeRoundTrip() {
        let original = settings.colorScheme
        defer { settings.colorScheme = original }

        for scheme in ConfiguredColorScheme.allCases {
            settings.colorScheme = scheme
            #expect(settings.colorScheme == scheme)
        }
    }

    @Test func defaultEpisodeSortOrderRoundTrip() {
        let originalSort = settings.defaultEpisodeSortOrder
        let originalAsc = settings.defaultEpisodeAscending
        defer {
            settings.defaultEpisodeSortOrder = originalSort
            settings.defaultEpisodeAscending = originalAsc
        }

        settings.defaultEpisodeSortOrder = .released
        settings.defaultEpisodeAscending = false
        #expect(settings.defaultEpisodeSortOrder == .released)
        #expect(settings.defaultEpisodeAscending == false)
    }

    @Test func audiobookFilteringAndSorting() {
        let originalAsc = settings.audiobooksAscending
        let originalSort = settings.audiobooksSortOrder
        let originalFilter = settings.audiobooksFilter
        let originalRestrict = settings.audiobooksRestrictToPersisted
        let originalDisplay = settings.audiobooksDisplayType
        defer {
            settings.audiobooksAscending = originalAsc
            settings.audiobooksSortOrder = originalSort
            settings.audiobooksFilter = originalFilter
            settings.audiobooksRestrictToPersisted = originalRestrict
            settings.audiobooksDisplayType = originalDisplay
        }

        settings.audiobooksAscending = true
        settings.audiobooksSortOrder = .duration
        settings.audiobooksFilter = .finished
        settings.audiobooksRestrictToPersisted = true
        settings.audiobooksDisplayType = .grid

        #expect(settings.audiobooksAscending == true)
        #expect(settings.audiobooksSortOrder == .duration)
        #expect(settings.audiobooksFilter == .finished)
        #expect(settings.audiobooksRestrictToPersisted == true)
        #expect(settings.audiobooksDisplayType == .grid)
    }

    @Test func authorAndNarratorSorting() {
        let originals = (
            authAsc: settings.authorsAscending,
            authSort: settings.authorsSortOrder,
            narAsc: settings.narratorsAscending,
            narSort: settings.narratorsSortOrder
        )
        defer {
            settings.authorsAscending = originals.authAsc
            settings.authorsSortOrder = originals.authSort
            settings.narratorsAscending = originals.narAsc
            settings.narratorsSortOrder = originals.narSort
        }

        settings.authorsAscending = false
        settings.authorsSortOrder = .lastNameFirstName
        settings.narratorsAscending = false
        settings.narratorsSortOrder = .bookCount

        #expect(settings.authorsAscending == false)
        #expect(settings.authorsSortOrder == .lastNameFirstName)
        #expect(settings.narratorsAscending == false)
        #expect(settings.narratorsSortOrder == .bookCount)
    }

    @Test func seriesSorting() {
        let originals = (
            sort: settings.seriesSortOrder,
            asc: settings.seriesAscending,
            display: settings.seriesDisplayType
        )
        defer {
            settings.seriesSortOrder = originals.sort
            settings.seriesAscending = originals.asc
            settings.seriesDisplayType = originals.display
        }

        settings.seriesSortOrder = .duration
        settings.seriesAscending = false
        settings.seriesDisplayType = .list

        #expect(settings.seriesSortOrder == .duration)
        #expect(settings.seriesAscending == false)
        #expect(settings.seriesDisplayType == .list)
    }

    @Test func bookmarksSortingRoundTrip() {
        let originalAsc = settings.bookmarksAscending
        let originalSort = settings.bookmarksSortOrder
        defer {
            settings.bookmarksAscending = originalAsc
            settings.bookmarksSortOrder = originalSort
        }

        settings.bookmarksAscending = false
        settings.bookmarksSortOrder = .bookmarkCount
        #expect(settings.bookmarksAscending == false)
        #expect(settings.bookmarksSortOrder == .bookmarkCount)
    }

    @Test func podcastSortingAndFilter() {
        let originalAsc = settings.podcastsAscending
        let originalSort = settings.podcastsSortOrder
        let originalFilter = settings.podcastsFilter
        let originalDisplay = settings.podcastsDisplayType
        defer {
            settings.podcastsAscending = originalAsc
            settings.podcastsSortOrder = originalSort
            settings.podcastsFilter = originalFilter
            settings.podcastsDisplayType = originalDisplay
        }

        settings.podcastsAscending = false
        settings.podcastsSortOrder = .episodeCount
        settings.podcastsFilter = .unfinished
        settings.podcastsDisplayType = .list

        #expect(settings.podcastsAscending == false)
        #expect(settings.podcastsSortOrder == .episodeCount)
        #expect(settings.podcastsFilter == .unfinished)
        #expect(settings.podcastsDisplayType == .list)
    }

    @Test func genresAndTagsAscending() {
        let originalGenres = settings.genresAscending
        let originalTags = settings.tagsAscending
        defer {
            settings.genresAscending = originalGenres
            settings.tagsAscending = originalTags
        }

        settings.genresAscending = false
        settings.tagsAscending = false
        #expect(settings.genresAscending == false)
        #expect(settings.tagsAscending == false)
    }

    // MARK: - Codable optionals

    @Test func lastPlayedItemIDRoundTrip() {
        let original = settings.lastPlayedItemID
        defer { settings.lastPlayedItemID = original }

        let id = ItemIdentifier(
            primaryID: "p",
            groupingID: nil,
            libraryID: "lib",
            connectionID: "conn",
            type: .audiobook
        )
        settings.lastPlayedItemID = id
        #expect(settings.lastPlayedItemID?.description == id.description)

        settings.lastPlayedItemID = nil
        #expect(settings.lastPlayedItemID == nil)
    }

    @Test func playbackResumeQueueRoundTrip() {
        let original = settings.playbackResumeQueue
        defer { settings.playbackResumeQueue = original }

        let ids = [
            ItemIdentifier(primaryID: "a", groupingID: nil, libraryID: "lib", connectionID: "conn", type: .audiobook),
            ItemIdentifier(primaryID: "ep", groupingID: "pod", libraryID: "lib", connectionID: "conn", type: .episode),
        ]
        settings.playbackResumeQueue = ids
        #expect(settings.playbackResumeQueue.count == 2)
        #expect(settings.playbackResumeQueue.map(\.description) == ids.map(\.description))

        settings.playbackResumeQueue = []
        #expect(settings.playbackResumeQueue.isEmpty)
    }

    // MARK: - Widget payloads

    @Test func listenedTodayWidgetValueRoundTrip() {
        let original = settings.listenedTodayWidgetValue
        defer { settings.listenedTodayWidgetValue = original }

        let updated = Date(timeIntervalSince1970: 1_800_000_000)
        let payload = ListenedTodayPayload(total: 42, updated: updated)
        settings.listenedTodayWidgetValue = payload
        #expect(settings.listenedTodayWidgetValue?.total == 42)
        #expect(settings.listenedTodayWidgetValue?.updated == updated)

        settings.listenedTodayWidgetValue = nil
        #expect(settings.listenedTodayWidgetValue == nil)
    }

    @Test func playbackInfoWidgetValueRoundTrip() {
        let original = settings.playbackInfoWidgetValue
        defer { settings.playbackInfoWidgetValue = original }

        let id = ItemIdentifier(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook)
        let payload = PlaybackInfoPayload(currentItemID: id, isPlaying: true)
        settings.playbackInfoWidgetValue = payload
        #expect(settings.playbackInfoWidgetValue?.currentItemID?.description == id.description)
        #expect(settings.playbackInfoWidgetValue?.isPlaying == true)

        settings.playbackInfoWidgetValue = nil
        #expect(settings.playbackInfoWidgetValue == nil)
    }

    // MARK: - Open sessions and miscellaneous

    @Test func openPlaybackSessionsRoundTrip() {
        let original = settings.openPlaybackSessions
        defer { settings.openPlaybackSessions = original }

        let id = ItemIdentifier(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook)
        let payload = OpenPlaybackSessionPayload(sessionID: "session-1", itemID: id)

        settings.openPlaybackSessions = [payload]
        #expect(settings.openPlaybackSessions.count == 1)
        #expect(settings.openPlaybackSessions.first?.sessionID == "session-1")
        #expect(settings.openPlaybackSessions.first?.id == "\(id.description)-session-1")

        settings.openPlaybackSessions = []
        #expect(settings.openPlaybackSessions.isEmpty)
    }

    @Test func dateRoundTrips() {
        let originalSpotlight = settings.spotlightIndexCompletionDate
        let originalConvenience = settings.lastConvenienceDownloadRun
        defer {
            settings.spotlightIndexCompletionDate = originalSpotlight
            settings.lastConvenienceDownloadRun = originalConvenience
        }

        let date = Date(timeIntervalSince1970: 1_777_000_000)
        settings.spotlightIndexCompletionDate = date
        settings.lastConvenienceDownloadRun = date

        #expect(settings.spotlightIndexCompletionDate == date)
        #expect(settings.lastConvenienceDownloadRun == date)

        settings.spotlightIndexCompletionDate = nil
        settings.lastConvenienceDownloadRun = nil
        #expect(settings.spotlightIndexCompletionDate == nil)
        #expect(settings.lastConvenienceDownloadRun == nil)
    }

    @Test func versionTrackingRoundTrip() {
        let originals = (
            build: settings.lastBuild,
            tos: settings.lastToSUpdate,
            server: settings.lastCheckedServerVersion,
            duration: settings.durationToggled,
            offline: settings.isOffline
        )
        defer {
            settings.lastBuild = originals.build
            settings.lastToSUpdate = originals.tos
            settings.lastCheckedServerVersion = originals.server
            settings.durationToggled = originals.duration
            settings.isOffline = originals.offline
        }

        settings.lastBuild = "9999"
        settings.lastToSUpdate = 5
        settings.lastCheckedServerVersion = "v2.99.0"
        settings.durationToggled = true
        settings.isOffline = true

        #expect(settings.lastBuild == "9999")
        #expect(settings.lastToSUpdate == 5)
        #expect(settings.lastCheckedServerVersion == "v2.99.0")
        #expect(settings.durationToggled == true)
        #expect(settings.isOffline == true)
    }

    @Test func convenienceDownloadFlags() {
        let originalConvenience = settings.enableConvenienceDownloads
        let originalListenNow = settings.enableListenNowDownloads
        let originalCellular = settings.allowCellularDownloads
        let originalUHQ = settings.ultraHighQuality
        defer {
            settings.enableConvenienceDownloads = originalConvenience
            settings.enableListenNowDownloads = originalListenNow
            settings.allowCellularDownloads = originalCellular
            settings.ultraHighQuality = originalUHQ
        }

        settings.enableConvenienceDownloads = false
        settings.enableListenNowDownloads = true
        settings.allowCellularDownloads = true
        settings.ultraHighQuality = true

        #expect(settings.enableConvenienceDownloads == false)
        #expect(settings.enableListenNowDownloads == true)
        #expect(settings.allowCellularDownloads == true)
        #expect(settings.ultraHighQuality == true)
    }

    @Test func advancedAppearanceFlags() {
        let originals = (
            serif: settings.enableSerifFont,
            singleEntry: settings.showSingleEntryGroupedSeries,
            percentage: settings.itemImageStatusPercentageText,
            lockSeek: settings.lockSeekBar,
            replaceVolume: settings.replaceVolumeWithTotalProgress
        )
        defer {
            settings.enableSerifFont = originals.serif
            settings.showSingleEntryGroupedSeries = originals.singleEntry
            settings.itemImageStatusPercentageText = originals.percentage
            settings.lockSeekBar = originals.lockSeek
            settings.replaceVolumeWithTotalProgress = originals.replaceVolume
        }

        settings.enableSerifFont = false
        settings.showSingleEntryGroupedSeries = false
        settings.itemImageStatusPercentageText = true
        settings.lockSeekBar = true
        settings.replaceVolumeWithTotalProgress = false

        #expect(settings.enableSerifFont == false)
        #expect(settings.showSingleEntryGroupedSeries == false)
        #expect(settings.itemImageStatusPercentageText == true)
        #expect(settings.lockSeekBar == true)
        #expect(settings.replaceVolumeWithTotalProgress == false)
    }

    @Test func multiplatformBoolToggles() {
        let originals = (
            carPlayOther: settings.carPlayShowOtherLibraries,
            haptic: settings.enableHapticFeedback,
            animated: settings.animatedNowPlayingBackground
        )
        defer {
            settings.carPlayShowOtherLibraries = originals.carPlayOther
            settings.enableHapticFeedback = originals.haptic
            settings.animatedNowPlayingBackground = originals.animated
        }

        settings.carPlayShowOtherLibraries.toggle()
        settings.enableHapticFeedback.toggle()
        settings.animatedNowPlayingBackground.toggle()

        #expect(settings.carPlayShowOtherLibraries == !originals.carPlayOther)
        #expect(settings.enableHapticFeedback == !originals.haptic)
        #expect(settings.animatedNowPlayingBackground == !originals.animated)
    }

    @Test func hiddenLibrariesRoundTrip() {
        let original = settings.hiddenLibraries
        defer { settings.hiddenLibraries = original }

        let lib1 = LibraryIdentifier(type: .audiobooks, libraryID: "lib-a", connectionID: "conn")
        let lib2 = LibraryIdentifier(type: .podcasts, libraryID: "lib-b", connectionID: "conn")

        settings.hiddenLibraries = [lib1, lib2]
        #expect(settings.hiddenLibraries.count == 2)
        #expect(settings.hiddenLibraries.contains(lib1))
        #expect(settings.hiddenLibraries.contains(lib2))

        settings.hiddenLibraries = []
        #expect(settings.hiddenLibraries.isEmpty)
    }
}

// MARK: - Isolated suite tests
//
// `AppSettings` is a singleton that wraps `UserDefaults`. We can still verify
// the underlying encode/decode behavior on which it relies by exercising it
// against an isolated suite, without going through the singleton.

@MainActor
struct AppSettingsIsolatedSuiteTests {
    @Test func userDefaultsCodableRoundTripUUIDSuite() throws {
        let suite = UserDefaults(suiteName: UUID().uuidString)!

        // Bool / Int / Double / String primitives the way AppSettings stores them.
        suite.set(true, forKey: "boolKey")
        suite.set(42, forKey: "intKey")
        suite.set(1.25, forKey: "doubleKey")
        suite.set("value", forKey: "stringKey")

        #expect(suite.object(forKey: "boolKey") as? Bool == true)
        #expect(suite.object(forKey: "intKey") as? Int == 42)
        #expect(suite.object(forKey: "doubleKey") as? Double == 1.25)
        #expect(suite.string(forKey: "stringKey") == "value")

        // Codable round-trip mirrors `encodeCodable` / `decodeCodable`.
        let payload = ListenedTodayPayload(total: 7, updated: Date(timeIntervalSince1970: 1_700_000_000))
        let data = try JSONEncoder().encode(payload)
        suite.set(data, forKey: "codableKey")

        let stored = suite.data(forKey: "codableKey")
        try #require(stored != nil)
        let decoded = try JSONDecoder().decode(ListenedTodayPayload.self, from: stored!)
        #expect(decoded.total == 7)
        #expect(decoded.updated.timeIntervalSince1970 == 1_700_000_000)

        // Removing the value returns nil, matching what `encodeCodable(nil, ...)` does.
        suite.removeObject(forKey: "codableKey")
        #expect(suite.data(forKey: "codableKey") == nil)
    }

    @Test func appSettingsSharedIsSingleton() {
        #expect(AppSettings.shared === AppSettings.shared)
    }
}
