//
//  ProgressAPITests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite(.serialized)
struct ProgressAPITests {
    private let audiobookLibraryID = "bbec293c-483c-4bc4-bad0-58b70644a615"
    private let prideAndPrejudiceID = "eef33983-a2d3-40b0-965f-dee2ceae34bc"

    private func authenticatedClient() async throws -> APIClient {
        let (accessToken, refreshToken) = try await ProgressAPITestsTokenCache.shared.tokens()
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

    // MARK: Get progress

    @Test func authorizeReturnsProgressList() async throws {
        let client = try await authenticatedClient()
        let (progress, _, _) = try await client.authorize()

        #expect(progress.count >= 0)

        for entry in progress {
            #expect(!entry.id.isEmpty)
            #expect(!entry.libraryItemId.isEmpty)
        }
    }

    // MARK: Mark finished / unfinished

    @Test func markFinishedRoundTrip() async throws {
        let client = try await authenticatedClient()
        let itemID = makeAudiobookID()

        // Mark finished, verify, then revert.
        try await client.finished(true, itemID: itemID)

        do {
            await client.flush()
            let (progress, _, _) = try await client.authorize()
            let entry = progress.first { $0.libraryItemId == itemID.primaryID && $0.episodeId == nil }

            if let entry {
                #expect(entry.isFinished)
            } else {
                Issue.record("Server did not return progress for the audiobook after marking it finished")
            }

            try await client.finished(false, itemID: itemID)

            await client.flush()
            let (afterReset, _, _) = try await client.authorize()
            if let resetEntry = afterReset.first(where: { $0.libraryItemId == itemID.primaryID && $0.episodeId == nil }) {
                #expect(!resetEntry.isFinished)
            }
        } catch {
            // Best-effort cleanup so the demo server is not left in a finished state.
            try? await client.finished(false, itemID: itemID)
            throw error
        }
    }

    // MARK: Listening sessions

    @Test func listListeningSessions() async throws {
        let client = try await authenticatedClient()
        let sessions = try await client.listeningSessions(page: 0, pageSize: 25)

        #expect(sessions.count >= 0)

        for session in sessions {
            #expect(!session.id.isEmpty)
        }
    }

    @Test func listListeningSessionsForItem() async throws {
        let client = try await authenticatedClient()
        let sessions = try await client.listeningSessions(from: makeAudiobookID(), page: 0, pageSize: 25)

        #expect(sessions.count >= 0)
    }

    // MARK: Edge cases

    @Test func progressForUnplayedItemMayBeAbsent() async throws {
        let client = try await authenticatedClient()

        // Use a random primaryID that almost certainly has no progress entry.
        let neverPlayedID = ItemIdentifier(
            primaryID: UUID().uuidString,
            groupingID: nil,
            libraryID: audiobookLibraryID,
            connectionID: "test-auth",
            type: .audiobook
        )

        let (progress, _, _) = try await client.authorize()
        let match = progress.first { $0.libraryItemId == neverPlayedID.primaryID }
        #expect(match == nil)
    }
}

// MARK: - Token Cache

/// Reuses a single login across all tests in this suite. The local
/// Audiobookshelf server applies a strict per-IP rate limit on `/login`, so
/// performing one login per test rapidly trips the limiter when multiple
/// suites run together.
private actor ProgressAPITestsTokenCache {
    static let shared = ProgressAPITestsTokenCache()

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
