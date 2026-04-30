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
        logger.info("Starting UserDefaults migration")

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

        var totalMigrated = 0

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

        var boolMigrated = 0
        for key in boolKeys {
            if let value = read(key) as? Bool {
                newSuite.set(value, forKey: key)
                boolMigrated += 1
            }
        }
        logger.debug("Migrated \(boolMigrated, privacy: .public) bool keys")
        totalMigrated += boolMigrated

        let intKeys = [
            "skipBackwardsInterval",
            "skipForwardsInterval",
            "sleepTimerExtendChapterAmount",
            "listenTimeTarget",
            "lastToSUpdate",
        ]

        var intMigrated = 0
        for key in intKeys {
            if let value = read(key) as? Int {
                newSuite.set(value, forKey: key)
                intMigrated += 1
            }
        }
        logger.debug("Migrated \(intMigrated, privacy: .public) int keys")
        totalMigrated += intMigrated

        let doubleKeys = [
            "defaultPlaybackRate",
            "sleepTimerExtendInterval",
        ]

        var doubleMigrated = 0
        for key in doubleKeys {
            if let value = read(key) as? Double {
                newSuite.set(value, forKey: key)
                doubleMigrated += 1
            }
        }
        logger.debug("Migrated \(doubleMigrated, privacy: .public) double keys")
        totalMigrated += doubleMigrated

        let stringKeys = [
            "lastBuild",
            "lastCheckedServerVersion",
            "clientId",
        ]

        var stringMigrated = 0
        for key in stringKeys {
            if let value = read(key) as? String {
                newSuite.set(value, forKey: key)
                stringMigrated += 1
            }
        }
        logger.debug("Migrated \(stringMigrated, privacy: .public) string keys")
        totalMigrated += stringMigrated

        let dateKeys = [
            "spotlightIndexCompletionDate",
            "lastConvenienceDownloadRun",
        ]

        var dateMigrated = 0
        for key in dateKeys {
            if let value = read(key) as? Date {
                newSuite.set(value, forKey: key)
                dateMigrated += 1
            }
        }
        logger.debug("Migrated \(dateMigrated, privacy: .public) date keys")
        totalMigrated += dateMigrated

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

        var intEnumMigrated = 0
        for key in intEnumKeys {
            if let value = read(key) as? Int {
                newSuite.set(value, forKey: key)
                intEnumMigrated += 1
            }
        }
        logger.debug("Migrated \(intEnumMigrated, privacy: .public) int-enum keys")
        totalMigrated += intEnumMigrated

        // Raw-value enum settings (stored as String)
        let stringEnumKeys = [
            "audiobookSortOrder",
            "seriesSortOrder",
        ]

        var stringEnumMigrated = 0
        for key in stringEnumKeys {
            if let value = read(key) as? String {
                newSuite.set(value, forKey: key)
                stringEnumMigrated += 1
            }
        }
        logger.debug("Migrated \(stringEnumMigrated, privacy: .public) string-enum keys")
        totalMigrated += stringEnumMigrated

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

        var dataMigrated = 0
        for key in dataKeys {
            if let value = read(key) as? Data {
                newSuite.set(value, forKey: key)
                dataMigrated += 1
            }
        }
        logger.debug("Migrated \(dataMigrated, privacy: .public) data-blob keys")
        totalMigrated += dataMigrated

        logger.info("Migrated \(totalMigrated, privacy: .public) keys")
    }
}
