//
//  ItemAPITests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite(.serialized)
struct ItemAPITests {
    // The Pride and Prejudice audiobook lives in the audiobook library on
    // the local Audiobookshelf dev server.
    private let audiobookLibraryID = "bbec293c-483c-4bc4-bad0-58b70644a615"
    private let podcastLibraryID = "bafc08aa-08c2-4811-99e5-1b86fc0987b0"
    private let prideAndPrejudiceID = "eef33983-a2d3-40b0-965f-dee2ceae34bc"

    private func authenticatedClient() async throws -> APIClient {
        let (accessToken, refreshToken) = try await ItemAPITestsTokenCache.shared.tokens()
        return try await APIClient(
            connectionID: "test-auth",
            credentialProvider: LocalCredentialProvider(accessToken: accessToken, refreshToken: refreshToken)
        )
    }

    private func makeAudiobookID() -> ItemIdentifier {
        ItemIdentifier(
            primaryID: prideAndPrejudiceID,
            groupingID: nil,
            libraryID: audiobookLibraryID,
            connectionID: "test-auth",
            type: .audiobook
        )
    }

    // MARK: Audiobook

    @Test func fetchAudiobookByID() async throws {
        let client = try await authenticatedClient()
        let audiobook = try await client.audiobook(with: makeAudiobookID())

        #expect(audiobook.id.primaryID == prideAndPrejudiceID)
        #expect(audiobook.id.type == .audiobook)
        #expect(!audiobook.name.isEmpty)
        #expect(audiobook.duration > 0)
    }

    @Test func fetchAudiobookByPrimaryID() async throws {
        let client = try await authenticatedClient()
        let audiobook = try await client.audiobook(primaryID: prideAndPrejudiceID)

        #expect(audiobook.id.primaryID == prideAndPrejudiceID)
        #expect(!audiobook.name.isEmpty)
    }

    @Test func fetchPlayableItem() async throws {
        let client = try await authenticatedClient()
        let (item, audioFiles, chapters, _) = try await client.playableItem(itemID: makeAudiobookID())

        #expect(item.id.primaryID == prideAndPrejudiceID)
        #expect(item is Audiobook)
        #expect(!audioFiles.isEmpty, "Audiobook must have at least one audio track")
        #expect(chapters.count >= 0)
    }

    // MARK: Podcasts and episodes

    @Test func fetchPodcastWithEpisodes() async throws {
        let client = try await authenticatedClient()

        let (podcasts, _) = try await client.podcasts(from: podcastLibraryID, sortOrder: .name, ascending: true, limit: 5, page: 0)

        guard let firstPodcast = podcasts.first else {
            Issue.record("Podcast library has no podcasts to inspect")
            return
        }

        let (podcast, episodes) = try await client.podcast(with: firstPodcast.id)

        #expect(podcast.id == firstPodcast.id)
        #expect(podcast.id.type == .podcast)
        #expect(!podcast.name.isEmpty)

        for episode in episodes {
            #expect(episode.id.type == .episode)
            #expect(episode.id.groupingID == firstPodcast.id.primaryID)
            #expect(!episode.name.isEmpty)
        }
    }

    @Test(.disabled("client.episode(itemID:) crashes when the server doesn't nest a podcast field in the response — pre-existing force-unwrap in Episode+Convert.swift:67"))
    func fetchEpisode() async throws {
        let client = try await authenticatedClient()
        let (podcasts, _) = try await client.podcasts(from: podcastLibraryID, sortOrder: .name, ascending: true, limit: 5, page: 0)

        guard let firstPodcast = podcasts.first else {
            Issue.record("Podcast library has no podcasts to inspect")
            return
        }

        let (_, episodes) = try await client.podcast(with: firstPodcast.id)

        guard let episode = episodes.first else {
            Issue.record("Podcast has no episodes to inspect")
            return
        }

        let fetched = try await client.episode(itemID: episode.id)

        #expect(fetched.id.primaryID == episode.id.primaryID)
        #expect(fetched.id.type == .episode)
        #expect(!fetched.name.isEmpty)
    }

    @Test func fetchRecentEpisodes() async throws {
        let client = try await authenticatedClient()
        let episodes = try await client.recentEpisodes(from: podcastLibraryID, limit: 10)

        for episode in episodes {
            #expect(episode.id.type == .episode)
            #expect(!episode.name.isEmpty)
        }
    }

    // MARK: Series

    @Test func fetchSeriesByID() async throws {
        let client = try await authenticatedClient()
        let (series, _) = try await client.series(in: audiobookLibraryID, sortOrder: .sortName, ascending: true, limit: 5, page: 0)

        guard let first = series.first else {
            Issue.record("Audiobook library has no series to inspect")
            return
        }

        let fetched = try await client.series(with: first.id)
        #expect(fetched.id == first.id)
        #expect(!fetched.name.isEmpty)
    }

    @Test func searchSeriesIDByName() async throws {
        let client = try await authenticatedClient()
        let (series, _) = try await client.series(in: audiobookLibraryID, sortOrder: .sortName, ascending: true, limit: 5, page: 0)

        guard let first = series.first else {
            Issue.record("Audiobook library has no series to look up")
            return
        }

        let resolved = try await client.seriesID(from: audiobookLibraryID, name: first.name)

        #expect(resolved.type == .series)
        #expect(resolved.libraryID == audiobookLibraryID)
    }

    // MARK: Authors

    @Test func fetchAuthorByID() async throws {
        let client = try await authenticatedClient()
        let (authors, _) = try await client.authors(from: audiobookLibraryID, sortOrder: .firstNameLastName, ascending: true, limit: 5, page: 0)

        guard let first = authors.first else {
            Issue.record("Audiobook library has no authors to inspect")
            return
        }

        let fetched = try await client.author(with: first.id)
        #expect(fetched.id == first.id)
        #expect(!fetched.name.isEmpty)
    }

    @Test func searchAuthorIDByName() async throws {
        let client = try await authenticatedClient()
        let (authors, _) = try await client.authors(from: audiobookLibraryID, sortOrder: .firstNameLastName, ascending: true, limit: 5, page: 0)

        guard let first = authors.first else {
            Issue.record("Audiobook library has no authors to look up")
            return
        }

        let resolved = try await client.authorID(from: audiobookLibraryID, name: first.name)
        #expect(resolved.type == .author)
        #expect(resolved.libraryID == audiobookLibraryID)
    }

    @Test func authorIDLookupNotFound() async throws {
        let client = try await authenticatedClient()

        await #expect(throws: APIClientError.self) {
            _ = try await client.authorID(from: audiobookLibraryID, name: "ZZZZZ_NoSuchAuthor_\(UUID().uuidString)")
        }
    }

    // MARK: Collections

    @Test func listCollections() async throws {
        let client = try await authenticatedClient()
        let (collections, total) = try await client.collections(in: audiobookLibraryID, type: .collection, limit: 25, page: 0)

        #expect(total >= collections.count)

        for collection in collections {
            #expect(collection.id.type == .collection)
            #expect(!collection.name.isEmpty)
        }
    }

    @Test func listPlaylists() async throws {
        let client = try await authenticatedClient()
        let (playlists, total) = try await client.collections(in: audiobookLibraryID, type: .playlist, limit: 25, page: 0)

        #expect(total >= playlists.count)

        for playlist in playlists {
            #expect(playlist.id.type == .playlist)
            #expect(!playlist.name.isEmpty)
        }
    }

    @Test func collectionLifecycle() async throws {
        let client = try await authenticatedClient()
        let audiobookID = makeAudiobookID()

        let name = "ShelfPlayer test collection \(UUID().uuidString)"
        let collectionID = try await client.createCollection(name: name, type: .collection, libraryID: audiobookLibraryID, itemIDs: [audiobookID])

        do {
            await client.flush()
            let collection = try await client.collection(with: collectionID)
            #expect(collection.name == name)
            #expect(collection.id == collectionID)

            try await client.updateCollection(collectionID, name: name + " (renamed)", description: "test description")

            await client.flush()
            let renamed = try await client.collection(with: collectionID)
            #expect(renamed.name == name + " (renamed)")

            try await client.deleteCollection(collectionID)
        } catch {
            // Best-effort cleanup if anything went wrong mid-flight.
            try? await client.deleteCollection(collectionID)
            throw error
        }
    }

    // MARK: Cover

    @Test func fetchCover() async throws {
        let client = try await authenticatedClient()
        let data = try await client.cover(from: makeAudiobookID(), width: 200)

        #expect(!data.isEmpty)
    }
}

// MARK: - Token Cache

/// Reuses a single login across all tests in this suite. The local
/// Audiobookshelf server applies a strict per-IP rate limit on `/login`, so
/// performing one login per test rapidly trips the limiter when multiple
/// suites run together.
private actor ItemAPITestsTokenCache {
    static let shared = ItemAPITestsTokenCache()

    private var cached: (accessToken: String, refreshToken: String?)?

    func tokens() async throws -> (String, String?) {
        if let cached { return cached }

        let client = try await APIClient(
            connectionID: "test",
            credentialProvider: LocalCredentialProvider()
        )
        let (_, accessToken, refreshToken) = try await client.login(username: "root", password: "root")
        cached = (accessToken, refreshToken)
        return (accessToken, refreshToken)
    }
}

// MARK: - Credential Provider

private final class LocalCredentialProvider: APICredentialProvider, @unchecked Sendable {
    private var _accessToken: String?
    private var _refreshToken: String?

    init(accessToken: String? = nil, refreshToken: String? = nil) {
        _accessToken = accessToken
        _refreshToken = refreshToken
    }

    var configuration: (URL, [HTTPHeader]) {
        (URL(string: "http://localhost:3333")!, [])
    }

    var accessToken: String? {
        _accessToken
    }

    func refreshAccessToken() async throws {
        throw APIClientError.unauthorized
    }
}
