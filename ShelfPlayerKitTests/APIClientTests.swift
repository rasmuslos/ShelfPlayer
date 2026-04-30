//
//  APIClientTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite(.serialized)
struct APIClientTests {
    let client: APIClient

    init() async throws {
        client = try await APIClient(
            connectionID: "test",
            credentialProvider: LocalCredentialProvider()
        )
    }

    // MARK: Authorization

    @Test func login() async throws {
        let (accessToken, _) = try await APIClientTokenCache.shared.tokens()
        #expect(!accessToken.isEmpty)
    }

    @Test func loginInvalidCredentials() async throws {
        await #expect(throws: APIClientError.self) {
            _ = try await client.login(username: "invalid", password: "wrong")
        }
    }

    @Test func status() async throws {
        let (version, strategies, isInit) = try await client.status()

        #expect(!version.isEmpty)
        #expect(!strategies.isEmpty)
        #expect(isInit)
    }

    @Test func ping() async {
        let reachable = await client.ping()
        #expect(reachable)
    }

    // MARK: Libraries

    @Test func libraries() async throws {
        let authenticatedClient = try await authenticatedClient()
        let libraries = try await authenticatedClient.libraries()

        #expect(!libraries.isEmpty)

        for library in libraries {
            #expect(!library.name.isEmpty)
            #expect(!library.id.libraryID.isEmpty)
        }
    }

    // MARK: Helpers

    private func authenticatedClient() async throws -> APIClient {
        let (accessToken, refreshToken) = try await APIClientTokenCache.shared.tokens()
        return try await APIClient(
            connectionID: "test-authenticated",
            credentialProvider: LocalCredentialProvider(accessToken: accessToken, refreshToken: refreshToken)
        )
    }
}

// MARK: - Token Cache

/// Reuses a single login across the whole suite. The local Audiobookshelf
/// server enforces a per-IP rate limit on `/login`, so logging in per test
/// trips it as soon as the suite is run together with the other API suites.
private actor APIClientTokenCache {
    static let shared = APIClientTokenCache()

    private var cached: (String, String?)?

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
