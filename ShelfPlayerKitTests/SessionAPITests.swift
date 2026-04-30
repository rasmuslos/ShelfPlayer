//
//  SessionAPITests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite(.serialized)
struct SessionAPITests {
    private let audiobookLibraryID = "bbec293c-483c-4bc4-bad0-58b70644a615"
    private let prideAndPrejudiceID = "eef33983-a2d3-40b0-965f-dee2ceae34bc"

    private func authenticatedClient() async throws -> APIClient {
        let (accessToken, refreshToken) = try await SessionAPITestsTokenCache.shared.tokens()
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

    // MARK: Listing

    @Test func listSessions() async throws {
        let client = try await authenticatedClient()
        let sessions = try await client.listeningSessions(page: 0, pageSize: 25)

        #expect(sessions.count >= 0)

        for session in sessions {
            #expect(!session.id.isEmpty)
            #expect(!session.libraryItemId.isEmpty)
            #expect(session.startTime >= 0)
        }
    }

    @Test func listSessionsForItem() async throws {
        let client = try await authenticatedClient()
        let sessions = try await client.listeningSessions(from: makeAudiobookID(), page: 0, pageSize: 25)

        #expect(sessions.count >= 0)

        for session in sessions {
            #expect(session.libraryItemId == prideAndPrejudiceID)
        }
    }

    // MARK: Playback session lifecycle

    @Test func startAndDeletePlaybackSession() async throws {
        let client = try await authenticatedClient()
        let itemID = makeAudiobookID()

        let (tracks, chapters, startTime, sessionID) = try await client.startPlaybackSession(itemID: itemID)

        #expect(!sessionID.isEmpty)
        #expect(startTime >= 0)
        #expect(!tracks.isEmpty, "A playback session should expose at least one audio track")
        #expect(chapters.count >= 0)

        // Close the session we just opened so we don't leave state lingering. The
        // /play endpoint creates an open session that only `close` can finalize —
        // `delete` only works on already-finished sessions.
        try await client.closeSession(sessionID: sessionID, currentTime: 0, duration: 0, timeListened: 0)
    }
}

// MARK: - Token Cache

/// Reuses a single login across all tests in this suite. The local
/// Audiobookshelf server applies a strict per-IP rate limit on `/login`, so
/// performing one login per test rapidly trips the limiter when multiple
/// suites run together.
private actor SessionAPITestsTokenCache {
    static let shared = SessionAPITestsTokenCache()

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
