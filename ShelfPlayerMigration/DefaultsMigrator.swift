//
//  DefaultsMigrator.swift
//  ShelfPlayerMigration
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import OSLog
import ShelfPlayerKit

enum DefaultsMigrator {
    private static let logger = Logger(subsystem: "io.rfk.shelfPlayerMigration", category: "DefaultsMigrator")

    static func migrate() {
        // The old app stored some keys in the shared group container
        // (`Defaults.Key(..., suite: .shared)`) and others in the bundle's
        // `UserDefaults.standard` (the Defaults library's default suite when no
        // suite is specified). Read from both, preferring the group container.
        // The standard fallback recovers values when the new bundle ID matches
        // the old one (true for release builds: `io.rfk.shelfplayer`).
        let oldGroupSuite = UserDefaults(suiteName: MigrationManager.oldGroupContainer)
        let standardSuite = UserDefaults.standard

        // Write to the same suite AppSettings reads from.
        let newSuite = ShelfPlayerKit.suite

        func read(_ key: String) -> Any? {
            oldGroupSuite?.object(forKey: key) ?? standardSuite.object(forKey: key)
        }

        let boolKeys = [
            "removeFinishedDownloads",
            "forceAspectRatio",
            "groupAudiobooksInSeries",
            "enableChapterTrack",
            "enableSmartRewind",
            "generateUpNextQueue",
            "sleepTimerFadeOut",
            "shakeExtendsSleepTimer",
            "extendSleepTimerOnPlay",
            "enableSerifFont",
            "showSingleEntryGroupedSeries",
            "itemImageStatusPercentageText",
            "lockSeekBar",
            "replaceVolumeWithTotalProgress",
            "allowCellularDownloads",
            "ultraHighQuality",
            "extendSleepTimerByPreviousSetting",
            "enableConvenienceDownloads",
            "enableListenNowDownloads",
            "audiobooksAscending",
            "audiobooksRestrictToPersisted",
            "authorsAscending",
            "narratorsAscending",
            "seriesAscending",
            "podcastsAscending",
            "durationToggled",
            "carPlayShowOtherLibraries",
            "enableHapticFeedback",
            "isOffline",
            "defaultEpisodeAscending",
        ]

        for key in boolKeys {
            if let value = read(key) as? Bool {
                newSuite.set(value, forKey: key)
            }
        }

        let intKeys = [
            "skipBackwardsInterval",
            "skipForwardsInterval",
            "sleepTimerExtendChapterAmount",
            "listenTimeTarget",
            "lastToSUpdate",
        ]

        for key in intKeys {
            if let value = read(key) as? Int {
                newSuite.set(value, forKey: key)
            }
        }

        let doubleKeys = [
            "defaultPlaybackRate",
            "sleepTimerExtendInterval",
        ]

        for key in doubleKeys {
            if let value = read(key) as? Double {
                newSuite.set(value, forKey: key)
            }
        }

        let stringKeys = [
            "lastBuild",
            "lastCheckedServerVersion",
            "clientId",
        ]

        for key in stringKeys {
            if let value = read(key) as? String {
                newSuite.set(value, forKey: key)
            }
        }

        let dateKeys = [
            "spotlightIndexCompletionDate",
            "lastConvenienceDownloadRun",
        ]

        for key in dateKeys {
            if let value = read(key) as? Date {
                newSuite.set(value, forKey: key)
            }
        }

        // Raw-value enum settings (stored as Int)
        let intEnumKeys = [
            "colorScheme",
            "audiobooksFilter",
            "audiobooksDisplayType",
            "authorsSortOrder",
            "narratorsSortOrder",
            "defaultEpisodeSortOrder",
            "podcastsSortOrder",
            "podcastsDisplayType",
            "seriesDisplayType",
        ]

        for key in intEnumKeys {
            if let value = read(key) as? Int {
                newSuite.set(value, forKey: key)
            }
        }

        // Raw-value enum settings (stored as String)
        let stringEnumKeys = [
            "audiobookSortOrder",
            "seriesSortOrder",
        ]

        for key in stringEnumKeys {
            if let value = read(key) as? String {
                newSuite.set(value, forKey: key)
            }
        }

        // Codable Data blobs (stored as Data, copied as-is)
        let dataKeys = [
            "playbackRates",
            "sleepTimerIntervals",
            "tintColor",
            "lastPlayedItemID",
            "playbackResumeQueue",
            "listenedTodayWidgetValue",
            "playbackInfoWidgetValue",
            "openPlaybackSessions",
            "pinnedTabValues",
            "lastTabValue",
            "carPlayTabBarLibraries",
        ]

        for key in dataKeys {
            if let value = read(key) as? Data {
                newSuite.set(value, forKey: key)
            }
        }

        logger.info("Migrated UserDefaults from old suites")
    }
}
