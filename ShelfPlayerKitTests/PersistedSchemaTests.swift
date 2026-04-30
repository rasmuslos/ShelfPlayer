//
//  PersistedSchemaTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
import SwiftData
@testable import ShelfPlayerKit

@MainActor
struct PersistedSchemaTests {
    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: ShelfPlayerSchema.self)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func audiobookID(_ primary: String = "book-1") -> ItemIdentifier {
        .init(primaryID: primary, groupingID: nil, libraryID: "lib", connectionID: "conn", type: .audiobook)
    }

    private func podcastID(_ primary: String = "pod-1") -> ItemIdentifier {
        .init(primaryID: primary, groupingID: nil, libraryID: "lib", connectionID: "conn", type: .podcast)
    }

    private func episodeID(_ primary: String = "ep-1", grouping: String = "pod-1") -> ItemIdentifier {
        .init(primaryID: primary, groupingID: grouping, libraryID: "lib", connectionID: "conn", type: .episode)
    }

    // MARK: - PersistedAudiobook

    @Test func persistedAudiobookRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let id = audiobookID("ab-rt")
        let audiobook = ShelfPlayerSchema.PersistedAudiobook(
            id: id,
            name: "Pride and Prejudice",
            authors: ["Jane Austen"],
            overview: "A novel.",
            genres: ["Classics"],
            addedAt: Date(timeIntervalSince1970: 1_700_000_000),
            released: "1813",
            size: 12_345,
            duration: 3600,
            subtitle: "A Novel",
            narrators: ["Karen Savage"],
            series: [.init(id: nil, name: "Austen", sequence: 1.0)],
            explicit: false,
            abridged: false
        )

        context.insert(audiobook)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedAudiobook>())
        try #require(fetched.count == 1)

        let stored = fetched[0]
        #expect(stored.id == id)
        #expect(stored.name == "Pride and Prejudice")
        #expect(stored.authors == ["Jane Austen"])
        #expect(stored.overview == "A novel.")
        #expect(stored.genres == ["Classics"])
        #expect(stored.released == "1813")
        #expect(stored.size == 12_345)
        #expect(stored.duration == 3600)
        #expect(stored.subtitle == "A Novel")
        #expect(stored.narrators == ["Karen Savage"])
        #expect(stored.series.count == 1)
        #expect(stored.series.first?.name == "Austen")
        #expect(stored.explicit == false)
        #expect(stored.abridged == false)
        #expect(stored.searchIndexEntry.primaryName == "Pride and Prejudice")
    }

    // MARK: - PersistedPodcast & PersistedEpisode

    @Test func persistedPodcastRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let id = podcastID("pod-rt")
        let podcast = ShelfPlayerSchema.PersistedPodcast(
            id: id,
            name: "Test Podcast",
            authors: ["Author A"],
            overview: "Overview.",
            genres: ["Tech"],
            addedAt: Date(timeIntervalSince1970: 1_700_000_000),
            released: "2024",
            explicit: true,
            publishingType: .episodic,
            totalEpisodeCount: 12,
            episodes: []
        )

        context.insert(podcast)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedPodcast>())
        try #require(fetched.count == 1)

        let stored = fetched[0]
        #expect(stored.id == id)
        #expect(stored.name == "Test Podcast")
        #expect(stored.authors == ["Author A"])
        #expect(stored.overview == "Overview.")
        #expect(stored.genres == ["Tech"])
        #expect(stored.released == "2024")
        #expect(stored.explicit == true)
        #expect(stored.publishingType == .episodic)
        #expect(stored.totalEpisodeCount == 12)
        #expect(stored.episodes.isEmpty)
    }

    @Test func persistedEpisodeAttachedToPodcast() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let podID = podcastID("pod-with-eps")
        let podcast = ShelfPlayerSchema.PersistedPodcast(
            id: podID,
            name: "Show",
            authors: [],
            genres: [],
            addedAt: Date(),
            released: nil,
            explicit: false,
            publishingType: .serial,
            totalEpisodeCount: 1,
            episodes: []
        )
        context.insert(podcast)

        let epID = episodeID("ep-x", grouping: "pod-with-eps")
        let episode = ShelfPlayerSchema.PersistedEpisode(
            id: epID,
            name: "Episode 1",
            authors: ["Host"],
            overview: "First.",
            addedAt: Date(timeIntervalSince1970: 1_700_000_500),
            released: "1700000500000",
            size: 5_000,
            duration: 60,
            podcast: podcast,
            type: .regular,
            index: .init(season: "1", episode: "1")
        )
        context.insert(episode)
        try context.save()

        let fetchedEps = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedEpisode>())
        try #require(fetchedEps.count == 1)

        let stored = fetchedEps[0]
        #expect(stored.id == epID)
        #expect(stored.name == "Episode 1")
        #expect(stored.authors == ["Host"])
        #expect(stored.overview == "First.")
        #expect(stored.size == 5_000)
        #expect(stored.duration == 60)
        #expect(stored.type == .regular)
        #expect(stored.index.season == "1")
        #expect(stored.index.episode == "1")
        #expect(stored.podcast.name == "Show")

        // Inverse relationship populated
        let fetchedPods = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedPodcast>())
        try #require(fetchedPods.count == 1)
        #expect(fetchedPods[0].episodes.count == 1)
    }

    // MARK: - PersistedProgress

    @Test func persistedProgressRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let now = Date()
        let progress = ShelfPlayerSchema.PersistedProgress(
            id: "progress-id-1",
            connectionID: "conn",
            primaryID: "book-1",
            groupingID: nil,
            progress: 0.5,
            duration: 3600,
            currentTime: 1800,
            startedAt: now.addingTimeInterval(-3600),
            lastUpdate: now,
            finishedAt: nil,
            status: .synchronized
        )

        context.insert(progress)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedProgress>())
        try #require(fetched.count == 1)

        let stored = fetched[0]
        #expect(stored.id == "progress-id-1")
        #expect(stored.connectionID == "conn")
        #expect(stored.primaryID == "book-1")
        #expect(stored.groupingID == nil)
        #expect(stored.progress == 0.5)
        #expect(stored.duration == 3600)
        #expect(stored.currentTime == 1800)
        #expect(stored.startedAt != nil)
        #expect(stored.finishedAt == nil)
        #expect(stored.status == .synchronized)
        #expect(stored.hasBeenSynchronised == true)
    }

    @Test func persistedProgressUpdatesMutableFields() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let progress = ShelfPlayerSchema.PersistedProgress(
            id: "progress-id-2",
            connectionID: "conn",
            primaryID: "book-2",
            groupingID: nil,
            progress: 0.1,
            duration: 100,
            currentTime: 10,
            lastUpdate: Date(),
            status: .desynchronized
        )

        context.insert(progress)
        try context.save()

        progress.progress = 0.9
        progress.currentTime = 90
        progress.status = .synchronized
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedProgress>())
        try #require(fetched.count == 1)
        #expect(fetched[0].progress == 0.9)
        #expect(fetched[0].currentTime == 90)
        #expect(fetched[0].status == .synchronized)
    }

    // MARK: - PersistedBookmark

    @Test func persistedBookmarkRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let now = Date()
        let bookmark = ShelfPlayerSchema.PersistedBookmark(
            connectionID: "conn",
            primaryID: "book-1",
            time: 1234,
            note: "Great chapter",
            created: now,
            status: .synced
        )

        context.insert(bookmark)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedBookmark>())
        try #require(fetched.count == 1)

        let stored = fetched[0]
        #expect(stored.connectionID == "conn")
        #expect(stored.primaryID == "book-1")
        #expect(stored.time == 1234)
        #expect(stored.note == "Great chapter")
        #expect(stored.status == .synced)
    }

    // MARK: - PersistedChapter

    @Test func persistedChapterRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let id = audiobookID("ab-chap")
        let chapter = ShelfPlayerSchema.PersistedChapter(
            index: 3,
            itemID: id,
            name: "Chapter 4",
            startOffset: 600,
            endOffset: 1200
        )

        context.insert(chapter)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedChapter>())
        try #require(fetched.count == 1)

        let stored = fetched[0]
        #expect(stored.index == 3)
        #expect(stored.name == "Chapter 4")
        #expect(stored.startOffset == 600)
        #expect(stored.endOffset == 1200)
        #expect(stored.itemID == id)
    }

    // MARK: - PersistedAsset

    @Test func persistedAssetRoundTripAudio() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let id = audiobookID("ab-asset")
        let asset = ShelfPlayerSchema.PersistedAsset(
            itemID: id,
            fileType: .audio(offset: 0, duration: 600, ino: "abc", fileExtension: "m4b"),
            progressWeight: 1.0
        )

        context.insert(asset)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedAsset>())
        try #require(fetched.count == 1)

        let stored = fetched[0]
        #expect(stored.itemID == id)
        #expect(stored.isDownloaded == false)
        #expect(stored.downloadTaskID == nil)
        #expect(stored.progressWeight == 1.0)
        #expect(stored.fileExtension == "m4b")

        if case .audio(let offset, let duration, let ino, let ext) = stored.fileType {
            #expect(offset == 0)
            #expect(duration == 600)
            #expect(ino == "abc")
            #expect(ext == "m4b")
        } else {
            Issue.record("Expected audio file type")
        }
    }

    @Test func persistedAssetFileTypeImageAndPDF() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let id = audiobookID("ab-asset-2")

        let pdf = ShelfPlayerSchema.PersistedAsset(
            itemID: id,
            fileType: .pdf(name: "supplement", ino: "i1"),
            progressWeight: 0.0
        )
        let image = ShelfPlayerSchema.PersistedAsset(
            itemID: id,
            fileType: .image(size: .regular),
            progressWeight: 0.0
        )

        context.insert(pdf)
        context.insert(image)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedAsset>())
        #expect(fetched.count == 2)
        #expect(fetched.contains { $0.fileExtension == "pdf" })
        #expect(fetched.contains { $0.fileExtension == "png" })
    }

    // MARK: - PersistedDominantColor

    @Test func persistedDominantColorRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let color = ShelfPlayerSchema.PersistedDominantColor(
            itemID: "item-1",
            red: 0.1,
            green: 0.2,
            blue: 0.3
        )

        context.insert(color)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedDominantColor>())
        try #require(fetched.count == 1)
        #expect(fetched[0].itemID == "item-1")
        #expect(fetched[0].red == 0.1)
        #expect(fetched[0].green == 0.2)
        #expect(fetched[0].blue == 0.3)
    }

    // MARK: - PersistedPlaybackRate

    @Test func persistedPlaybackRateRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let rate = ShelfPlayerSchema.PersistedPlaybackRate(itemID: "item-2", rate: 1.5, isCachePurgeable: true)
        context.insert(rate)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedPlaybackRate>())
        try #require(fetched.count == 1)
        #expect(fetched[0].itemID == "item-2")
        #expect(fetched[0].rate == 1.5)
        #expect(fetched[0].isCachePurgeable == true)
    }

    @Test func persistedPlaybackRateDefaultsToNonPurgeable() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let rate = ShelfPlayerSchema.PersistedPlaybackRate(itemID: "item-3", rate: 1.0)
        context.insert(rate)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedPlaybackRate>())
        try #require(fetched.count == 1)
        #expect(fetched[0].isCachePurgeable == false)
    }

    // MARK: - PersistedSleepTimerConfig

    @Test func persistedSleepTimerConfigRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let payload = "config-bytes".data(using: .utf8)!
        let config = ShelfPlayerSchema.PersistedSleepTimerConfig(itemID: "item-4", configData: payload)
        context.insert(config)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ShelfPlayerSchema.PersistedSleepTimerConfig>())
        try #require(fetched.count == 1)
        #expect(fetched[0].itemID == "item-4")
        #expect(fetched[0].configData == payload)
    }
}
