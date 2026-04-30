//
//  ConvertOfflineTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct ConvertOfflineTests {
    // MARK: - Helpers

    private func audiobookID(_ primary: String = "ab-1") -> ItemIdentifier {
        .init(primaryID: primary, groupingID: nil, libraryID: "lib", connectionID: "conn", type: .audiobook)
    }

    private func podcastID(_ primary: String = "pod-1") -> ItemIdentifier {
        .init(primaryID: primary, groupingID: nil, libraryID: "lib", connectionID: "conn", type: .podcast)
    }

    private func episodeID(_ primary: String = "ep-1", grouping: String = "pod-1") -> ItemIdentifier {
        .init(primaryID: primary, groupingID: grouping, libraryID: "lib", connectionID: "conn", type: .episode)
    }

    // MARK: - Audiobook

    @Test func audiobookFromPersisted() {
        let id = audiobookID("ab-convert")
        let added = Date(timeIntervalSince1970: 1_700_000_000)

        let persisted = ShelfPlayerSchema.PersistedAudiobook(
            id: id,
            name: "Pride and Prejudice",
            authors: ["Jane Austen"],
            overview: "Romance.",
            genres: ["Classics", "Romance"],
            addedAt: added,
            released: "1813",
            size: 9_999,
            duration: 7200,
            subtitle: "Subtitle",
            narrators: ["Narrator A", "Narrator B"],
            series: [.init(id: nil, name: "Standalone", sequence: nil)],
            explicit: false,
            abridged: true
        )

        let audiobook = Audiobook(downloaded: persisted)

        #expect(audiobook.id == id)
        #expect(audiobook.name == "Pride and Prejudice")
        #expect(audiobook.authors == ["Jane Austen"])
        #expect(audiobook.description == "Romance.")
        #expect(audiobook.genres == ["Classics", "Romance"])
        #expect(audiobook.addedAt == added)
        #expect(audiobook.released == "1813")
        #expect(audiobook.size == 9_999)
        #expect(audiobook.duration == 7200)
        #expect(audiobook.subtitle == "Subtitle")
        #expect(audiobook.narrators == ["Narrator A", "Narrator B"])
        #expect(audiobook.series.count == 1)
        #expect(audiobook.series.first?.name == "Standalone")
        #expect(audiobook.explicit == false)
        #expect(audiobook.abridged == true)
    }

    @Test func audiobookFromPersistedWithMinimalFields() {
        let id = audiobookID("ab-min")
        let persisted = ShelfPlayerSchema.PersistedAudiobook(
            id: id,
            name: "Minimal",
            authors: [],
            genres: [],
            addedAt: Date(),
            size: nil,
            duration: 0,
            narrators: [],
            series: [],
            explicit: false,
            abridged: false
        )

        let audiobook = Audiobook(downloaded: persisted)
        #expect(audiobook.id == id)
        #expect(audiobook.description == nil)
        #expect(audiobook.released == nil)
        #expect(audiobook.size == nil)
        #expect(audiobook.subtitle == nil)
        #expect(audiobook.series.isEmpty)
    }

    // MARK: - Podcast

    @Test func podcastFromPersisted() {
        let id = podcastID("pod-convert")
        let added = Date(timeIntervalSince1970: 1_700_000_500)

        let persisted = ShelfPlayerSchema.PersistedPodcast(
            id: id,
            name: "Daily Show",
            authors: ["Host"],
            overview: "A daily podcast.",
            genres: ["News"],
            addedAt: added,
            released: "2024",
            explicit: true,
            publishingType: .episodic,
            totalEpisodeCount: 42,
            episodes: []
        )

        let podcast = Podcast(downloaded: persisted)

        #expect(podcast.id == id)
        #expect(podcast.name == "Daily Show")
        #expect(podcast.authors == ["Host"])
        #expect(podcast.description == "A daily podcast.")
        #expect(podcast.genres == ["News"])
        #expect(podcast.addedAt == added)
        #expect(podcast.released == "2024")
        #expect(podcast.explicit == true)
        #expect(podcast.episodeCount == 42)
        #expect(podcast.incompleteEpisodeCount == nil)
        #expect(podcast.publishingType == .episodic)
    }

    // MARK: - Episode

    @Test func episodeFromPersisted() {
        let podID = podcastID("pod-for-ep")
        let podcast = ShelfPlayerSchema.PersistedPodcast(
            id: podID,
            name: "Parent Show",
            authors: [],
            genres: [],
            addedAt: Date(),
            released: nil,
            explicit: false,
            publishingType: .serial,
            totalEpisodeCount: 1,
            episodes: []
        )

        let epID = episodeID("ep-convert", grouping: "pod-for-ep")
        let added = Date(timeIntervalSince1970: 1_700_000_900)

        let persisted = ShelfPlayerSchema.PersistedEpisode(
            id: epID,
            name: "Episode One",
            authors: ["Host"],
            overview: "First.",
            addedAt: added,
            released: "1700000900000",
            size: 7_654,
            duration: 1234,
            podcast: podcast,
            type: .bonus,
            index: .init(season: "2", episode: "5")
        )

        let episode = Episode(downloaded: persisted)

        #expect(episode.id == epID)
        #expect(episode.name == "Episode One")
        #expect(episode.authors == ["Host"])
        #expect(episode.description == "First.")
        #expect(episode.addedAt == added)
        #expect(episode.released == "1700000900000")
        #expect(episode.size == 7_654)
        #expect(episode.duration == 1234)
        #expect(episode.podcastName == "Parent Show")
        #expect(episode.type == .bonus)
        #expect(episode.index.season == "2")
        #expect(episode.index.episode == "5")
    }

    // MARK: - Progress

    @Test func progressFromPersisted() {
        let now = Date()
        let started = now.addingTimeInterval(-3600)

        let persisted = ShelfPlayerSchema.PersistedProgress(
            id: "p-convert",
            connectionID: "conn",
            primaryID: "book-1",
            groupingID: nil,
            progress: 0.42,
            duration: 600,
            currentTime: 252,
            startedAt: started,
            lastUpdate: now,
            finishedAt: nil,
            status: .synchronized
        )

        let entity = ProgressEntity(persistedEntity: persisted)

        #expect(entity.id == "p-convert")
        #expect(entity.connectionID == "conn")
        #expect(entity.primaryID == "book-1")
        #expect(entity.groupingID == nil)
        #expect(entity.progress == 0.42)
        #expect(entity.duration == 600)
        #expect(entity.currentTime == 252)
        #expect(entity.startedAt == started)
        #expect(entity.lastUpdate == now)
        #expect(entity.finishedAt == nil)
        #expect(entity.isFinished == false)
    }

    @Test func progressFromPersistedFinished() {
        let now = Date()
        let persisted = ShelfPlayerSchema.PersistedProgress(
            id: "p-finished",
            connectionID: "conn",
            primaryID: "ep-1",
            groupingID: "pod-1",
            progress: 1.0,
            duration: 100,
            currentTime: 100,
            startedAt: now.addingTimeInterval(-100),
            lastUpdate: now,
            finishedAt: now,
            status: .synchronized
        )

        let entity = ProgressEntity(persistedEntity: persisted)
        #expect(entity.groupingID == "pod-1")
        #expect(entity.finishedAt == now)
        #expect(entity.isFinished == true)
    }
}
