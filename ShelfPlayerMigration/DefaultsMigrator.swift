//
//  DefaultsMigrator.swift
//  ShelfPlayerMigration
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import OSLog

enum DefaultsMigrator {
    private static let logger = Logger(subsystem: "io.rfk.shelfPlayerMigration", category: "DefaultsMigrator")

    static func migrate() {
        let oldSuite = UserDefaults(suiteName: MigrationManager.oldGroupContainer) ?? .standard
        let newSuite = UserDefaults.standard

        // Bool settings
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
        ]

        for key in boolKeys {
            if oldSuite.object(forKey: key) != nil {
                newSuite.set(oldSuite.bool(forKey: key), forKey: key)
            }
        }

        // Int settings
        let intKeys = [
            "skipBackwardsInterval",
            "skipForwardsInterval",
            "sleepTimerExtendChapterAmount",
            "listenTimeTarget",
            "lastToSUpdate",
        ]

        for key in intKeys {
            if let value = oldSuite.object(forKey: key) as? Int {
                newSuite.set(value, forKey: key)
            }
        }

        // Double settings
        let doubleKeys = [
            "defaultPlaybackRate",
            "playbackRateAdjustmentUp",
            "playbackRateAdjustmentDown",
            "sleepTimerExtendInterval",
        ]

        for key in doubleKeys {
            if oldSuite.object(forKey: key) != nil {
                newSuite.set(oldSuite.double(forKey: key), forKey: key)
            }
        }

        // String settings
        let stringKeys = [
            "lastBuild",
            "lastCheckedServerVersion",
            "clientId",
        ]

        for key in stringKeys {
            if let value = oldSuite.string(forKey: key) {
                newSuite.set(value, forKey: key)
            }
        }

        // Date settings
        let dateKeys = [
            "spotlightIndexCompletionDate",
            "lastConvenienceDownloadRun",
        ]

        for key in dateKeys {
            if let value = oldSuite.object(forKey: key) as? Date {
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
            if let value = oldSuite.object(forKey: key) as? Int {
                newSuite.set(value, forKey: key)
            }
        }

        // Raw-value enum settings (stored as String)
        let stringEnumKeys = [
            "audiobookSortOrder",
            "seriesSortOrder",
        ]

        for key in stringEnumKeys {
            if let value = oldSuite.string(forKey: key) {
                newSuite.set(value, forKey: key)
            }
        }

        // Bool stored in shared suite (old group defaults)
        let sharedBoolKeys = [
            "isOffline",
            "defaultEpisodeAscending",
        ]

        for key in sharedBoolKeys {
            if oldSuite.object(forKey: key) != nil {
                newSuite.set(oldSuite.bool(forKey: key), forKey: key)
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
            if let value = oldSuite.data(forKey: key) {
                newSuite.set(value, forKey: key)
            }
        }

        logger.info("Migrated UserDefaults from old suite")
    }
}
