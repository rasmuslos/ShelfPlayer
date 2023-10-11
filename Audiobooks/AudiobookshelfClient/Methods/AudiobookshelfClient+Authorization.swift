//
//  AudiobookshelfClient+Authorization.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

// MARK: Ping

extension AudiobookshelfClient {
    func ping() async throws {
        let response = try await request(ClientRequest<PingResponse>(path: "ping", method: "GET"))
        
        if !response.success {
            throw AudiobookshelfClientError.invalidResponse
        }
    }
    
    struct PingResponse: Codable {
        let success: Bool
    }
}

// MARK: Login

extension AudiobookshelfClient {
    func login(username: String, password: String) async throws -> String {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "login", method: "POST", body: [
            "username": username,
            "password": password,
        ]))
        return response.user.token
    }
}

// MARK: Authorize

extension AudiobookshelfClient {
    func authorize() async throws -> [MediaProgress] {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "api/authorize", method: "POST"))
        return response.user.mediaProgress
    }
}

// MARK: Authorization response

extension AudiobookshelfClient {
    struct AuthorizationResponse: Codable {
        let user: User
        
        struct User: Codable {
            let id: String
            let token: String
            
            let mediaProgress: [MediaProgress]
        }
    }
}
