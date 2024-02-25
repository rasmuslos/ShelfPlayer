//
//  AudiobookshelfClient+Authorization.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

public extension AudiobookshelfClient {
    func status() async throws -> StatusResponse {
        return try await request(ClientRequest<StatusResponse>(path: "status", method: "GET"))
    }
    func openIDExchange(code: String, state: String, verifier: String) async throws -> String {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "auth/openid/callback", method: "GET", query: [
            .init(name: "code", value: code),
            .init(name: "state", value: state),
            .init(name: "code_verifier", value: verifier),
        ]))
        
        return response.user.token
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
