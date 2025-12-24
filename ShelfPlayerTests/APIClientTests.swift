//
//  ShelfPlayerTests.swift
//  ShelfPlayerTests
//
//  Created by Rasmus Krämer on 22.12.25.
//

import Testing
import Foundation
@testable import ShelfPlayerKit

@Suite("Networking", .serialized)
struct APIClientTests {
    let client: APIClient
    let credentialProvider: TestAPICredentialProvider
    
    let username: String
    
    init() async throws {
        let (username, accessToken, refreshToken) = try await TestAPICredentialProvider.authData()
        
        self.username = username
        credentialProvider = .init(accessToken: accessToken, refreshToken: refreshToken)
        self.client = try await APIClient(connectionID: "testing-authorized", credentialProvider: credentialProvider)
    }
    
    @Test func get() async throws {
        await client.resetRequestCount()
        let result = try await client.response(APIRequest<StatusResponse>(path: "status", method: .get))
        
        try #require(result.isInit)
        try await #require(client.requestCount == 1)
    }
    
    @Test func deduplicate() async throws {
        await client.resetRequestCount()
        try await withThrowingTaskGroup {
            for _ in 1..<20 {
                $0.addTask { try await client.response(APIRequest<StatusResponse>(path: "status", method: .get)) }
            }
            
            return try await $0.waitForAll()
        }
        
        try await #require(client.requestCount == 1)
    }
    
    @Test func cache() async throws {
        await client.resetRequestCount()
        
        let _ = try await client.response(APIRequest<StatusResponse>(path: "status", method: .get, ttl: 20))
        let _ = try await client.response(APIRequest<StatusResponse>(path: "status", method: .get, ttl: 20))
        
        try await #require(client.requestCount == 2)
    }
    @Test func noCache() async throws {
        await client.resetRequestCount()
        
        let _ = try await client.response(APIRequest<StatusResponse>(path: "status", method: .get))
        let _ = try await client.response(APIRequest<StatusResponse>(path: "status", method: .get))
        
        try await #require(client.requestCount == 2)
    }
    
    @Test func queue() async throws {
        await client.resetRequestCount()
        
        try await withThrowingTaskGroup {
            for n in 0..<10 {
                $0.addTask {
                    let response = try await client.response(APIRequest<StatusResponse>(path: "status", method: .get, timeout: Double(n) * 2))
                    try #require(response.isInit)
                }
            }
            
            return try await $0.waitForAll()
        }
        
        try await #require(client.requestCount == 10)
    }
    
    @Test func me() async throws {
        try await #require(client.response(APIRequest<MeResponse>(path: "api/me", method: .get)).username == username)
    }
    @Test func refreshJWT() async throws {
        await MainActor.run {
            credentialProvider.accessToken = nil
        }
        
        try await withThrowingTaskGroup {
            for n in 0..<5 {
                $0.addTask {
                    let response = try await client.response(APIRequest<MeResponse>(path: "api/me", method: .get, timeout: Double(n) * 2))
                    return response
                }
            }
            
            return try await $0.waitForAll()
        }
    }
    
    @Test func error() async throws {
        do {
            let _ = try await client.response(APIRequest<MeResponse>(path: "404", method: .get))
            #expect(Bool(false))
        } catch {
            #expect(true)
        }
    }
    
    @Test func data() async throws {
        let response = try await client.response(APIRequest<APIClient.DataResponse>(path: "status", method: .get))
        try #require(response.data.count > 0)
    }
    @Test func empty() async throws {
        let _ = try await client.response(APIRequest<APIClient.EmptyResponse>(path: "status", method: .get))
    }
}

final class TestAPICredentialProvider: APICredentialProvider {
    var configuration: (URL, [HTTPHeader]) {
        (.init(string: "https://audiobooks.dev")!, [])
    }
    
    @MainActor var accessToken: String?
    @MainActor var refreshToken: String?
    
    init(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func refreshAccessToken() async throws {
        let (_, accessToken, refreshToken) = try await Self.authData()
        
        await MainActor.run {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
        }
    }
    
    static func authData() async throws -> (String, String, String?) {
        let client = try await APIClient(connectionID: "testing-bootstrap", credentialProvider: TestAPICredentialProvider(accessToken: nil, refreshToken: nil))
        let (username, accessToken, refreshToken) = try await client.login(username: "demo", password: "demo")
        
        return (username, accessToken, refreshToken)
    }
}
