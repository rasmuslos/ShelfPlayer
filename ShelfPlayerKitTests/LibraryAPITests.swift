//
//  LibraryAPITests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite(.serialized)
struct LibraryAPITests {
    private func authenticatedClient() async throws -> APIClient {
        let (accessToken, refreshToken) = try await LibraryAPITestsTokenCache.shared.tokens()
        return try await APIClient(
            connectionID: "test-auth",
            credentialProvider: LocalCredentialProvider(accessToken: accessToken, refreshToken: refreshToken)
        )
    }

    private func audiobookLibrary() async throws -> Library {
        let client = try await authenticatedClient()
        let libraries = try await client.libraries()

        return try #require(libraries.first(where: { $0.id.type == .audiobooks }), "Audiobook library required")
    }

    private func podcastLibrary() async throws -> Library {
        let client = try await authenticatedClient()
        let libraries = try await client.libraries()

        return try #require(libraries.first(where: { $0.id.type == .podcasts }), "Podcast library required")
    }

    // MARK: Filter data

    @Test func fetchTags() async throws {
        let client = try await authenticatedClient()
        let library = try await audiobookLibrary()

        let tags = try await client.tags(from: library.id.libraryID)
        #expect(tags is [String])
    }

    @Test func fetchGenresForPodcastLibrary() async throws {
        let client = try await authenticatedClient()
        let library = try await podcastLibrary()

        let genres = try await client.genres(from: library.id.libraryID)
        #expect(genres is [String])
    }

    // MARK: Personalized / home

    @Test func audiobookHome() async throws {
        let client = try await authenticatedClient()
        let library = try await audiobookLibrary()

        let (audiobookRows, authorRows, seriesRows) = try await client.home(for: library.id.libraryID)

        for row in audiobookRows {
            #expect(!row.id.isEmpty)
            #expect(!row.label.isEmpty)
            #expect(!row.entities.isEmpty)
            for entity in row.entities {
                #expect(entity.id.type == .audiobook)
            }
        }

        for row in authorRows {
            for entity in row.entities {
                #expect(entity.id.type == .author)
            }
        }

        for row in seriesRows {
            for entity in row.entities {
                #expect(entity.id.type == .series)
            }
        }
    }

    @Test func podcastHome() async throws {
        let client = try await authenticatedClient()
        let library = try await podcastLibrary()

        let (podcastRows, episodeRows) = try await client.home(for: library.id.libraryID)

        for row in podcastRows {
            for entity in row.entities {
                #expect(entity.id.type == .podcast)
            }
        }

        for row in episodeRows {
            for entity in row.entities {
                #expect(entity.id.type == .episode)
            }
        }
    }

    // MARK: Series

    @Test func fetchSeries() async throws {
        let client = try await authenticatedClient()
        let library = try await audiobookLibrary()

        let (series, total) = try await client.series(in: library.id.libraryID, sortOrder: .sortName, ascending: true, limit: 50, page: 0)

        #expect(total >= series.count)

        for entry in series {
            #expect(!entry.name.isEmpty)
            #expect(entry.id.type == .series)
        }
    }

    // MARK: Podcasts

    @Test func fetchPodcasts() async throws {
        let client = try await authenticatedClient()
        let library = try await podcastLibrary()

        let (podcasts, total) = try await client.podcasts(from: library.id.libraryID, sortOrder: .name, ascending: true, limit: 50, page: 0)

        #expect(!podcasts.isEmpty, "Podcast library should expose at least one podcast")
        #expect(total >= podcasts.count)

        for podcast in podcasts {
            #expect(!podcast.name.isEmpty)
            #expect(podcast.id.type == .podcast)
        }
    }

    // MARK: Authors

    @Test func fetchAuthors() async throws {
        let client = try await authenticatedClient()
        let library = try await audiobookLibrary()

        let (authors, total) = try await client.authors(from: library.id.libraryID, sortOrder: .firstNameLastName, ascending: true, limit: 50, page: 0)

        #expect(total >= authors.count)

        for author in authors {
            #expect(!author.name.isEmpty)
            #expect(author.id.type == .author)
        }
    }

    // MARK: Audiobook listings

    @Test func fetchAudiobooksAll() async throws {
        let client = try await authenticatedClient()
        let library = try await audiobookLibrary()

        let (sections, total) = try await client.audiobooks(from: library.id.libraryID, filter: .all, sortOrder: .sortName, ascending: true, limit: 25, page: 0)

        #expect(!sections.isEmpty, "Audiobook library should expose at least one item")
        #expect(total >= sections.count)
    }
}

// MARK: - Token Cache

/// Reuses a single login across all tests in this suite. The local
/// Audiobookshelf server applies a strict per-IP rate limit on `/login`, so
/// performing one login per test rapidly trips the limiter when multiple
/// suites run together.
private actor LibraryAPITestsTokenCache {
    static let shared = LibraryAPITestsTokenCache()

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
