//
//  ContentAPITests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite(.serialized)
struct ContentAPITests {
    private func authenticatedClient() async throws -> APIClient {
        let (accessToken, refreshToken) = try await ContentAPITokenCache.shared.tokens()

        return try await APIClient(
            connectionID: "test-auth",
            credentialProvider: StaticCredentialProvider(accessToken: accessToken, refreshToken: refreshToken)
        )
    }

    // MARK: Libraries

    @Test func fetchLibraries() async throws {
        let client = try await authenticatedClient()
        let libraries = try await client.libraries()

        #expect(!libraries.isEmpty)

        let audioLibrary = libraries.first(where: { $0.id.type == .audiobooks })
        #expect(audioLibrary != nil)

        let podcastLibrary = libraries.first(where: { $0.id.type == .podcasts })
        #expect(podcastLibrary != nil)
    }

    @Test func fetchGenres() async throws {
        let client = try await authenticatedClient()
        let libraries = try await client.libraries()

        guard let library = libraries.first(where: { $0.id.type == .audiobooks }) else {
            Issue.record("No audiobook library available")
            return
        }

        let genres = try await client.genres(from: library.id.libraryID)
        #expect(genres is [String])
    }

    // MARK: Search

    @Test func searchItems() async throws {
        let client = try await authenticatedClient()
        let libraries = try await client.libraries()

        guard let library = libraries.first(where: { $0.id.type == .audiobooks }) else {
            Issue.record("No audiobook library available")
            return
        }

        let (audiobooks, _, _, _, _, _) = try await client.items(in: library.id, search: "Pride")

        #expect(!audiobooks.isEmpty, "Local server should have at least one audiobook matching 'Pride'")
    }

    // MARK: Authorization

    @Test func me() async throws {
        let client = try await authenticatedClient()
        let (userID, username) = try await client.me()

        #expect(!userID.isEmpty)
        #expect(username == "root")
    }

    @Test func authorize() async throws {
        let client = try await authenticatedClient()
        let (progress, bookmarks, _) = try await client.authorize()

        #expect(progress.count >= 0)
        #expect(bookmarks.count >= 0)
    }
}

// MARK: - Token Cache

/// Reuses a single login across the whole suite. The local Audiobookshelf
/// server enforces a per-IP rate limit on `/login`, so logging in per test
/// trips it as soon as the suite is run together with the other API suites.
private actor ContentAPITokenCache {
    static let shared = ContentAPITokenCache()

    private var cached: (String, String?)?

    func tokens() async throws -> (String, String?) {
        if let cached { return cached }

        let client = try await APIClient(
            connectionID: "test",
            credentialProvider: StaticCredentialProvider()
        )
        let (_, accessToken, refreshToken) = try await client.login(username: "root", password: "root")
        cached = (accessToken, refreshToken)
        return (accessToken, refreshToken)
    }
}

// MARK: - Credential Provider

private final class StaticCredentialProvider: APICredentialProvider, @unchecked Sendable {
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
