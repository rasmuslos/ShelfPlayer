//
//  SwiftDataMigrator.swift
//  ShelfPlayerMigration
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData
import OSLog
import ShelfPlayerKit

enum SwiftDataMigrator {
    private static let logger = Logger(subsystem: "io.rfk.shelfPlayerMigration", category: "SwiftDataMigrator")

    static func migrate(progress: @escaping (Double) -> Void) async throws {
        let oldContainer = try openOldContainer()
        let newContainer = PersistenceManager.shared.modelContainer

        let oldContext = ModelContext(oldContainer)
        oldContext.autosaveEnabled = false

        let newContext = ModelContext(newContainer)
        newContext.autosaveEnabled = false

        progress(0.0)
        try migrateAudiobooks(from: oldContext, to: newContext)
        progress(0.1)

        try migratePodcastsAndEpisodes(from: oldContext, to: newContext)
        progress(0.25)

        try migrateProgress(from: oldContext, to: newContext)
        progress(0.35)

        try migrateSessions(from: oldContext, to: newContext)
        progress(0.45)

        try migrateBookmarks(from: oldContext, to: newContext)
        progress(0.5)

        try migrateChapters(from: oldContext, to: newContext)
        progress(0.55)

        try migrateAssets(from: oldContext, to: newContext)
        progress(0.6)

        try migrateDiscoveredConnections(from: oldContext, to: newContext)
        progress(0.65)

        try migratePlaybackRates(from: oldContext, to: newContext)
        progress(0.7)

        try migrateSleepTimerConfigs(from: oldContext, to: newContext)
        progress(0.75)

        try migrateUpNextStrategies(from: oldContext, to: newContext)
        progress(0.8)

        try migrateDominantColors(from: oldContext, to: newContext)
        progress(0.85)

        try migratePodcastFilterSorts(from: oldContext, to: newContext)
        progress(0.9)

        try migrateTabCustomizations(from: oldContext, to: newContext)
        progress(0.92)

        try migrateLibraryIndices(from: oldContext, to: newContext)
        progress(0.95)

        try await migrateConvenienceDownloads(from: oldContext)
        progress(0.97)

        try newContext.save()
        progress(1.0)

        logger.info("SwiftData migration complete")
    }

    // MARK: - Container

    private static func openOldContainer() throws -> ModelContainer {
        let groupContainer = MigrationManager.oldGroupContainer

        let schema = Schema([
            PersistedAudiobook.self,
            PersistedEpisode.self,
            PersistedPodcast.self,
            PersistedProgress.self,
            PersistedPlaybackSession.self,
            PersistedBookmark.self,
            PersistedChapter.self,
            PersistedAsset.self,
            PersistedSearchIndexEntry.self,
            PersistedDiscoveredConnection.self,
            PersistedKeyValueEntity.self,
        ])

        let configuration = ModelConfiguration("ShelfPlayerUpdated",
                                               schema: schema,
                                               isStoredInMemoryOnly: false,
                                               allowsSave: true,
                                               groupContainer: .identifier(groupContainer),
                                               cloudKitDatabase: .none)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Audiobooks

    private static func migrateAudiobooks(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedAudiobook>()
        let audiobooks = try oldContext.fetch(descriptor)

        for old in audiobooks {
            let id = ItemIdentifier(string: old._id)

            let new = ShelfPlayerSchema.PersistedAudiobook(
                id: id,
                name: old.name,
                authors: old.authors,
                overview: old.overview,
                genres: old.genres,
                addedAt: old.addedAt,
                released: old.released,
                size: old.size,
                duration: old.duration,
                subtitle: old.subtitle,
                narrators: old.narrators,
                series: old.series,
                explicit: old.explicit,
                abridged: old.abridged
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(audiobooks.count) audiobooks")
    }

    // MARK: - Podcasts & Episodes

    private static func migratePodcastsAndEpisodes(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let podcastDescriptor = FetchDescriptor<PersistedPodcast>()
        let podcasts = try oldContext.fetch(podcastDescriptor)

        for oldPodcast in podcasts {
            let podcastID = ItemIdentifier(string: oldPodcast._id)

            let newPodcast = ShelfPlayerSchema.PersistedPodcast(
                id: podcastID,
                name: oldPodcast.name,
                authors: oldPodcast.authors,
                overview: oldPodcast.overview,
                genres: oldPodcast.genres,
                addedAt: oldPodcast.addedAt,
                released: oldPodcast.released,
                explicit: oldPodcast.explicit,
                publishingType: oldPodcast.publishingType,
                totalEpisodeCount: oldPodcast.totalEpisodeCount,
                episodes: []
            )

            newContext.insert(newPodcast)

            for oldEpisode in oldPodcast.episodes {
                let episodeID = ItemIdentifier(string: oldEpisode._id)

                let newEpisode = ShelfPlayerSchema.PersistedEpisode(
                    id: episodeID,
                    name: oldEpisode.name,
                    authors: oldEpisode.authors,
                    overview: oldEpisode.overview,
                    addedAt: oldEpisode.addedAt,
                    released: oldEpisode.released,
                    size: oldEpisode.size,
                    duration: oldEpisode.duration,
                    podcast: newPodcast,
                    type: oldEpisode.type,
                    index: oldEpisode.index
                )

                newContext.insert(newEpisode)
            }

            logger.info("Migrated podcast \(oldPodcast.name) with \(oldPodcast.episodes.count) episodes")
        }
    }

    // MARK: - Progress

    private static func migrateProgress(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedProgress>()
        let entries = try oldContext.fetch(descriptor)

        for old in entries {
            let new = ShelfPlayerSchema.PersistedProgress(
                id: old.id,
                connectionID: old.connectionID,
                primaryID: old.primaryID,
                groupingID: old.groupingID,
                progress: old.progress,
                duration: old.duration,
                currentTime: old.currentTime,
                startedAt: old.startedAt,
                lastUpdate: old.lastUpdate,
                finishedAt: old.finishedAt,
                status: .desynchronized
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(entries.count) progress entries")
    }

    // MARK: - Sessions

    private static func migrateSessions(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedPlaybackSession>()
        let sessions = try oldContext.fetch(descriptor)

        for old in sessions {
            let itemID = ItemIdentifier(string: old._itemID)

            let new = ShelfPlayerSchema.PersistedPlaybackSession(
                itemID: itemID,
                duration: old.duration,
                currentTime: old.currentTime,
                startTime: old.startTime,
                timeListened: old.timeListened
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(sessions.count) playback sessions")
    }

    // MARK: - Bookmarks

    private static func migrateBookmarks(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedBookmark>()
        let bookmarks = try oldContext.fetch(descriptor)

        for old in bookmarks {
            let new = ShelfPlayerSchema.PersistedBookmark(
                connectionID: old.connectionID,
                primaryID: old.primaryID,
                time: old.time,
                note: old.note,
                created: old.created,
                status: .pendingUpdate
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(bookmarks.count) bookmarks")
    }

    // MARK: - Chapters

    private static func migrateChapters(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedChapter>()
        let chapters = try oldContext.fetch(descriptor)

        for old in chapters {
            let itemID = ItemIdentifier(string: old._itemID)

            let new = ShelfPlayerSchema.PersistedChapter(
                index: old.index,
                itemID: itemID,
                name: old.name,
                startOffset: old.startOffset,
                endOffset: old.endOffset
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(chapters.count) chapters")
    }

    // MARK: - Assets

    private static func migrateAssets(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedAsset>()
        let assets = try oldContext.fetch(descriptor)

        for old in assets {
            let itemID = ItemIdentifier(string: old._itemID)

            let new = ShelfPlayerSchema.PersistedAsset(
                id: old.id,
                itemID: itemID,
                fileType: old.fileType,
                isDownloaded: old.isDownloaded,
                progressWeight: old.progressWeight
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(assets.count) assets")
    }

    // MARK: - Discovered Connections

    private static func migrateDiscoveredConnections(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedDiscoveredConnection>()
        let connections = try oldContext.fetch(descriptor)

        for old in connections {
            let new = ShelfPlayerSchema.PersistedDiscoveredConnection(
                connectionID: old.connectionID,
                host: old.host,
                user: old.user
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(connections.count) discovered connections")
    }

    // MARK: - Key-Value Entity Clusters

    private static func migratePlaybackRates(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "playbackRates" })
        let entities = try oldContext.fetch(descriptor)

        for entity in entities {
            guard let rate = try? JSONDecoder().decode(Double.self, from: entity.value) else { continue }

            let new = ShelfPlayerSchema.PersistedPlaybackRate(itemID: entity.key, rate: rate)
            newContext.insert(new)
        }

        logger.info("Migrated \(entities.count) playback rates")
    }

    private static func migrateSleepTimerConfigs(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "sleepTimers" })
        let entities = try oldContext.fetch(descriptor)

        for entity in entities {
            let new = ShelfPlayerSchema.PersistedSleepTimerConfig(itemID: entity.key, configData: entity.value)
            newContext.insert(new)
        }

        logger.info("Migrated \(entities.count) sleep timer configs")
    }

    private static func migrateUpNextStrategies(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let strategyDescriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "upNextStrategy" })
        let strategies = try oldContext.fetch(strategyDescriptor)

        let suggestionsDescriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "allowSuggestions" })
        let suggestions = try oldContext.fetch(suggestionsDescriptor)
        let suggestionsMap = Dictionary(uniqueKeysWithValues: suggestions.map { ($0.key, $0) })

        for entity in strategies {
            guard let strategy = String(data: entity.value, encoding: .utf8) else { continue }

            let allowSuggestions: Bool? = suggestionsMap[entity.key].flatMap {
                try? JSONDecoder().decode(Bool.self, from: $0.value)
            }

            let new = ShelfPlayerSchema.PersistedUpNextStrategy(
                itemID: entity.key,
                strategy: strategy,
                allowSuggestions: allowSuggestions
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(strategies.count) up-next strategies")
    }

    private static func migrateDominantColors(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "dominantColors" })
        let entities = try oldContext.fetch(descriptor)

        for entity in entities {
            guard let colorString = String(data: entity.value, encoding: .utf8) else { continue }

            let components = colorString.split(separator: ":")
            guard components.count == 3,
                  let red = Double(components[0]),
                  let green = Double(components[1]),
                  let blue = Double(components[2]) else { continue }

            let new = ShelfPlayerSchema.PersistedDominantColor(
                itemID: entity.key,
                red: red,
                green: green,
                blue: blue
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(entities.count) dominant colors")
    }

    private static func migratePodcastFilterSorts(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "podcastFilterSortConfigurations" })
        let entities = try oldContext.fetch(descriptor)

        for entity in entities {
            guard let config = try? JSONDecoder().decode(OldPodcastFilterSortConfig.self, from: entity.value) else { continue }

            let new = ShelfPlayerSchema.PersistedPodcastFilterSort(
                podcastID: entity.key,
                sortOrder: config.sortOrder,
                ascending: config.ascending,
                filter: config.filter,
                restrictToPersisted: config.restrictToPersisted,
                seasonFilter: config.seasonFilter
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(entities.count) podcast filter/sort configs")
    }

    private static func migrateTabCustomizations(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "storedTabIDs" })
        let entities = try oldContext.fetch(descriptor)

        for entity in entities {
            let parts = entity.key.split(separator: "::", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let libraryID = String(parts[0])
            let scope = String(parts[1])

            let new = ShelfPlayerSchema.PersistedTabCustomization(
                libraryID: libraryID,
                scope: scope,
                tabsData: entity.value
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(entities.count) tab customizations")
    }

    private static func migrateLibraryIndices(from oldContext: ModelContext, to newContext: ModelContext) throws {
        let descriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "libraryIndexMetadata" })
        let entities = try oldContext.fetch(descriptor)

        for entity in entities {
            guard let index = try? JSONDecoder().decode(OldLibraryIndexMetadata.self, from: entity.value) else { continue }

            let new = ShelfPlayerSchema.PersistedLibraryIndex(
                libraryKey: entity.key,
                page: index.page,
                totalItemCount: index.totalItemCount,
                startDate: index.startDate,
                endDate: index.endDate,
                indexedIDsData: index.indexedIDsData
            )

            newContext.insert(new)
        }

        logger.info("Migrated \(entities.count) library indices")
    }

    // MARK: - Convenience Downloads

    private static func migrateConvenienceDownloads(from oldContext: ModelContext) async throws {
        typealias GroupingRetrieval = PersistenceManager.ConvenienceDownloadSubsystem.GroupingRetrieval

        var retrievals = [String: GroupingRetrieval]()
        var downloadedItemIDs = [String: Set<ItemIdentifier>]()
        var associatedConfigurationIDs = [ItemIdentifier: Set<String>]()

        let retrievalDescriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "convenienceDownloadRetrievals" })
        let retrievalEntities = try oldContext.fetch(retrievalDescriptor)

        for entity in retrievalEntities {
            guard let retrieval = try? JSONDecoder().decode(GroupingRetrieval.self, from: entity.value) else { continue }

            // Old key: "convenienceDownloadRetrieval-{configurationID}", new store uses raw configurationID
            let configurationID = entity.key.replacingOccurrences(of: "convenienceDownloadRetrieval-", with: "")
            retrievals[configurationID] = retrieval
        }

        let downloadedDescriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "downloadedItemIDs" })
        let downloadedEntities = try oldContext.fetch(downloadedDescriptor)

        for entity in downloadedEntities {
            guard let ids = try? JSONDecoder().decode(Set<ItemIdentifier>.self, from: entity.value) else { continue }

            // Old key: "downloadedItemIDs-{configurationID}", new store uses raw configurationID
            let configurationID = entity.key.replacingOccurrences(of: "downloadedItemIDs-", with: "")
            downloadedItemIDs[configurationID] = ids
        }

        let associatedDescriptor = FetchDescriptor<PersistedKeyValueEntity>(predicate: #Predicate { $0.cluster == "associatedConfigurationIDs" })
        let associatedEntities = try oldContext.fetch(associatedDescriptor)

        for entity in associatedEntities {
            guard let ids = try? JSONDecoder().decode(Set<String>.self, from: entity.value) else { continue }

            // Old key: "associatedConfigurationIDs-{itemID}", new store uses ItemIdentifier
            let itemIDString = entity.key.replacingOccurrences(of: "associatedConfigurationIDs-", with: "")
            let itemID = ItemIdentifier(itemIDString)
            associatedConfigurationIDs[itemID] = ids
        }

        await PersistenceManager.shared.convenienceDownload.restoreMigratedState(
            retrievals: retrievals,
            downloadedItemIDs: downloadedItemIDs,
            associatedConfigurationIDs: associatedConfigurationIDs
        )

        logger.info("Migrated convenience downloads: \(retrievals.count) retrievals, \(downloadedItemIDs.count) downloaded sets, \(associatedConfigurationIDs.count) associations")
    }
}

// MARK: - Old Schema Models

/// These model classes replicate the old ShelfPlayer app's SchemaV2 SwiftData models.
/// Class names match the old schema entity names so SwiftData can read the existing store.
/// Property names and types must exactly match the persisted schema.

@Model
final class PersistedAudiobook {
    var _id: String = ""

    var name: String = ""
    var authors: [String] = []

    var overview: String?
    var genres: [String] = []

    var addedAt: Date = Date.distantPast
    var released: String?

    var size: Int64?
    var duration: TimeInterval = 0

    var subtitle: String?
    var narrators: [String] = []

    var series: [Audiobook.SeriesFragment] = []

    var explicit: Bool = false
    var abridged: Bool = false

    var searchIndexEntry: PersistedSearchIndexEntry?

    init() {}
}

@Model
final class PersistedEpisode {
    var _id: String = ""

    var name: String = ""
    var authors: [String] = []

    var overview: String?

    var addedAt: Date = Date.distantPast
    var released: String?

    var size: Int64?
    var duration: TimeInterval = 0

    var type: Episode.EpisodeType = Episode.EpisodeType.regular
    var index: Episode.EpisodeIndex = Episode.EpisodeIndex(season: nil, episode: "0")

    var podcast: PersistedPodcast?
    var searchIndexEntry: PersistedSearchIndexEntry?

    init() {}
}

@Model
final class PersistedPodcast {
    var _id: String = ""

    var name: String = ""
    var authors: [String] = []

    var overview: String?
    var genres: [String] = []

    var addedAt: Date = Date.distantPast
    var released: String?

    var explicit: Bool = false
    var publishingType: Podcast.PodcastType?

    var totalEpisodeCount: Int = 0

    @Relationship(inverse: \PersistedEpisode.podcast)
    var episodes: [PersistedEpisode] = []

    init() {}
}

@Model
final class PersistedProgress {
    var id: String = ""

    var connectionID: String = ""

    var primaryID: String = ""
    var groupingID: String?

    var progress: Double = 0

    var duration: TimeInterval?
    var currentTime: TimeInterval = 0

    var startedAt: Date?
    var lastUpdate: Date = Date.distantPast
    var finishedAt: Date?

    var hasBeenSynchronised: Bool = true

    init() {}
}

@Model
final class PersistedPlaybackSession {
    var id: UUID = Foundation.UUID()
    var _itemID: String = ""

    var duration: TimeInterval = 0
    var currentTime: TimeInterval = 0

    var startTime: TimeInterval = 0
    var timeListened: TimeInterval = 0

    var started: Date = Date.distantPast
    var lastUpdated: Date = Date.distantPast

    var eligibleForEarlySync: Bool = false

    init() {}
}

@Model
final class PersistedBookmark {
    var id: UUID = Foundation.UUID()

    var primaryID: String = ""
    var connectionID: String = ""

    var time: UInt64 = 0
    var note: String = ""

    var created: Date = Date.distantPast

    init() {}
}

@Model
final class PersistedChapter {
    var id: UUID = Foundation.UUID()
    var index: Int = 0
    var _itemID: String = ""

    var name: String = ""

    var startOffset: TimeInterval = 0
    var endOffset: TimeInterval = 0

    init() {}
}

@Model
final class PersistedAsset {
    var id: UUID = Foundation.UUID()
    var _itemID: String = ""

    var fileType: ShelfPlayerSchema.PersistedAsset.FileType = ShelfPlayerSchema.PersistedAsset.FileType.image(size: ImageSize.regular)

    var isDownloaded: Bool = false
    var downloadTaskID: Int?

    var progressWeight: Double = 0

    init() {}
}

@Model
final class PersistedSearchIndexEntry {
    var _itemID: String = ""

    var primaryName: String = ""
    var secondaryName: String?

    var authors: [String] = []
    var authorName: String = ""

    init() {}
}

@Model
final class PersistedDiscoveredConnection {
    var connectionID: String = ""

    var host: URL = Foundation.URL(fileURLWithPath: "/")
    var user: String = ""

    init() {}
}

@Model
final class PersistedKeyValueEntity {
    var id: UUID = Foundation.UUID()

    var key: String = ""
    var cluster: String = ""

    var value: Data = Data()

    var isCachePurgeable: Bool = false

    init() {}
}

// MARK: - Intermediate Decodable Types

private struct OldPodcastFilterSortConfig: Codable {
    var sortOrder: Int
    var ascending: Bool
    var filter: Int
    var restrictToPersisted: Bool
    var seasonFilter: String?
}

private struct OldLibraryIndexMetadata: Codable {
    var page: Int
    var totalItemCount: Int?
    var startDate: Date?
    var endDate: Date?
    var indexedIDsData: Data?
}
