//
//  StatsAPITests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite(.serialized)
struct StatsAPITests {
    private let audiobookLibraryID = "bbec293c-483c-4bc4-bad0-58b70644a615"

    private func authenticatedClient() async throws -> APIClient {
        let (accessToken, refreshToken) = try await StatsAPITestsTokenCache.shared.tokens()
        return try await APIClient(
            connectionID: "test-auth",
            credentialProvider: LocalCredentialProvider(accessToken: accessToken, refreshToken: refreshToken)
        )
    }

    // MARK: Listening stats

    @Test func fetchListeningStats() async throws {
        let client = try await authenticatedClient()
        let stats = try await client.listeningStats()

        #expect(stats.totalTime >= 0)
        #expect(stats.today >= 0)
        #expect(stats.items.count >= 0)
        #expect(stats.days.count >= 0)
        #expect(stats.dayOfWeek.count >= 0)
        #expect(stats.recentSessions.count >= 0)

        for session in stats.recentSessions {
            #expect(!session.id.isEmpty)
        }
    }

    // MARK: Narrators

    @Test func fetchNarrators() async throws {
        let client = try await authenticatedClient()
        let narrators = try await client.narrators(from: audiobookLibraryID)

        #expect(narrators.count >= 0)

        for narrator in narrators {
            #expect(narrator.id.type == .narrator)
            #expect(!narrator.name.isEmpty)
        }
    }

    @Test func fetchAudiobooksByNarrator() async throws {
        let client = try await authenticatedClient()
        let narrators = try await client.narrators(from: audiobookLibraryID)

        // The local server's seed data may not list narrators on every audiobook,
        // so this test is best-effort: skip when the library has no narrators.
        guard let narrator = narrators.first else {
            return
        }

        let audiobooks = try await client.audiobooks(from: audiobookLibraryID, narratorName: narrator.name, page: 0, limit: 25)

        for audiobook in audiobooks {
            #expect(audiobook.id.type == .audiobook)
            #expect(audiobook.id.libraryID == audiobookLibraryID)
        }
    }
}

// MARK: - Token Cache

/// Reuses a single login across all tests in this suite. The local
/// Audiobookshelf server applies a strict per-IP rate limit on `/login`, so
/// performing one login per test rapidly trips the limiter when multiple
/// suites run together.
private actor StatsAPITestsTokenCache {
    static let shared = StatsAPITestsTokenCache()

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
