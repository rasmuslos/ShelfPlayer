//
//  APIClientTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct APIClientTests {
    let client: APIClient

    init() async throws {
        client = try await APIClient(
            connectionID: "test",
            credentialProvider: DemoCredentialProvider()
        )
    }

    // MARK: Authorization

    @Test func login() async throws {
        let (username, accessToken, _) = try await client.login(username: "demo", password: "demo")

        #expect(username.hasPrefix("demo"))
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
        let (_, accessToken, refreshToken) = try await client.login(username: "demo", password: "demo")
        return try await APIClient(
            connectionID: "test-authenticated",
            credentialProvider: DemoCredentialProvider(accessToken: accessToken, refreshToken: refreshToken)
        )
    }
}

// MARK: - Credential Provider

private final class DemoCredentialProvider: APICredentialProvider, @unchecked Sendable {
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
