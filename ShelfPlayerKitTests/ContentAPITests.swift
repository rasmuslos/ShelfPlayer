//
//  ContentAPITests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct ContentAPITests {
    private func authenticatedClient() async throws -> APIClient {
        let client = try await APIClient(
            connectionID: "test",
            credentialProvider: StaticCredentialProvider()
        )

        let (_, accessToken, refreshToken) = try await client.login(username: "demo", password: "demo")

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
    }

    @Test func fetchGenres() async throws {
        let client = try await authenticatedClient()
        let libraries = try await client.libraries()

        guard let library = libraries.first else {
            Issue.record("No libraries available")
            return
        }

        let genres = try await client.genres(from: library.id.libraryID)
        #expect(genres is [String])
    }

    // MARK: Search

    @Test func searchItems() async throws {
        let client = try await authenticatedClient()
        let libraries = try await client.libraries()

        guard let library = libraries.first else {
            Issue.record("No libraries available")
            return
        }

        let (audiobooks, _, _, _, _, _) = try await client.items(in: library.id, search: "a")

        // Demo server should have some content
        #expect(audiobooks is [Audiobook])
    }

    // MARK: Authorization

    @Test func me() async throws {
        let client = try await authenticatedClient()
        let (userID, username) = try await client.me()

        #expect(!userID.isEmpty)
        #expect(username.hasPrefix("demo"))
    }

    @Test func authorize() async throws {
        let client = try await authenticatedClient()
        let (progress, bookmarks, _) = try await client.authorize()

        #expect(progress.count >= 0)
        #expect(bookmarks.count >= 0)
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
        (URL(string: "https://audiobooks.dev")!, [])
    }

    var accessToken: String? {
        _accessToken
    }

    func refreshAccessToken() async throws {
        throw APIClientError.unauthorized
    }
}
