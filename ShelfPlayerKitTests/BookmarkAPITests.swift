//
//  BookmarkAPITests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite(.serialized)
struct BookmarkAPITests {
    private let prideAndPrejudiceID = "eef33983-a2d3-40b0-965f-dee2ceae34bc"

    private func authenticatedClient() async throws -> APIClient {
        let (accessToken, refreshToken) = try await BookmarkAPITestsTokenCache.shared.tokens()
        return try await APIClient(
            connectionID: "test-auth",
            credentialProvider: LocalCredentialProvider(accessToken: accessToken, refreshToken: refreshToken)
        )
    }

    // MARK: List

    @Test func listBookmarksViaAuthorize() async throws {
        let client = try await authenticatedClient()
        let (_, bookmarks, _) = try await client.authorize()

        #expect(bookmarks.count >= 0)

        for bookmark in bookmarks {
            #expect(!bookmark.libraryItemId.isEmpty)
            #expect(!bookmark.title.isEmpty)
        }
    }

    // MARK: Lifecycle

    @Test func createUpdateDeleteBookmark() async throws {
        let client = try await authenticatedClient()

        // Use an unusual time offset so we don't collide with a pre-existing bookmark.
        let time: UInt64 = 314_159
        let title = "ShelfPlayerKitTests bookmark \(UUID().uuidString)"

        let createdAt = try await client.createBookmark(primaryID: prideAndPrejudiceID, time: time, note: title)
        #expect(createdAt.timeIntervalSince1970 > 0)

        do {
            await client.flush()
            let (_, bookmarks, _) = try await client.authorize()
            let matching = bookmarks.first {
                $0.libraryItemId == prideAndPrejudiceID && Int($0.time) == Int(time)
            }

            let bookmark = try #require(matching, "Bookmark should appear after creation")
            #expect(bookmark.title == title)

            // Update the title and verify.
            let renamed = title + " (edited)"
            try await client.updateBookmark(primaryID: prideAndPrejudiceID, time: time, note: renamed)

            await client.flush()
            let (_, updated, _) = try await client.authorize()
            let updatedBookmark = updated.first {
                $0.libraryItemId == prideAndPrejudiceID && Int($0.time) == Int(time)
            }
            #expect(updatedBookmark?.title == renamed)
        } catch {
            try? await client.deleteBookmark(primaryID: prideAndPrejudiceID, time: time)
            throw error
        }

        // Cleanup.
        try await client.deleteBookmark(primaryID: prideAndPrejudiceID, time: time)

        await client.flush()
        let (_, afterDelete, _) = try await client.authorize()
        let stillThere = afterDelete.first {
            $0.libraryItemId == prideAndPrejudiceID && Int($0.time) == Int(time)
        }
        #expect(stillThere == nil, "Bookmark should be removed after deletion")
    }
}

// MARK: - Token Cache

/// Reuses a single login across all tests in this suite. The local
/// Audiobookshelf server applies a strict per-IP rate limit on `/login`, so
/// performing one login per test rapidly trips the limiter when multiple
/// suites run together.
private actor BookmarkAPITestsTokenCache {
    static let shared = BookmarkAPITestsTokenCache()

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
