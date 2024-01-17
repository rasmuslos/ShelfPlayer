//
//  AudiobookshelfClient+Authorization.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

// MARK: Ping

public extension AudiobookshelfClient {
    func ping() async throws {
        let response = try await request(ClientRequest<PingResponse>(path: "ping", method: "GET"))
        
        if !response.success {
            throw AudiobookshelfClientError.invalidResponse
        }
    }
    
    func login(username: String, password: String) async throws -> String {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "login", method: "POST", body: [
            "username": username,
            "password": password,
        ]))
        return response.user.token
    }
    
    func getUsername() async throws -> String {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "api/authorize", method: "POST"))
        return response.user.username
    }
    
    func authorize() async throws -> [MediaProgress] {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "api/authorize", method: "POST"))
        return response.user.mediaProgress
    }
}
