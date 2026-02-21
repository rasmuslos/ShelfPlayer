//
//  AudiobookshelfClient+Authorization.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

public extension APIClient {
    func login(username: String, password: String) async throws -> (username: String, accessToken: String, refreshToken: String?) {
        let response = try await response(APIRequest<AuthorizationResponse>(
            path: "login",
            method: .post,
            body: [
                "username": username,
                "password": password,
            ],
            headers: ["x-return-tokens": "true"],
            bypassesOffline: true,
            bypassesScheduler: true,
        ))
        
        return try (response.user.username, response.versionSafeAccessToken, response.versionSafeRefreshToken)
    }
    
    func status() async throws -> (String, [AuthorizationStrategy], Bool) {
        let response = try await response(APIRequest<StatusResponse>(path: "status", method: .get, maxAttempts: 4, bypassesOffline: true, bypassesScheduler: true))
        
        let strategies: [AuthorizationStrategy] = response.authMethods.compactMap {
            switch $0 {
                case "local":
                    .usernamePassword
                case "openid":
                    .openID
                default:
                    nil
            }
        }
        
        return (response.serverVersion, strategies, response.isInit)
    }
    func ping(timeout: TimeInterval = OfflineMode.availabilityTimeout) async -> Bool {
        (try? await response(APIRequest<APIClient.EmptyResponse>(path: "ping", method: .get, timeout: timeout, maxAttempts: 2, bypassesOffline: true, bypassesScheduler: true))) != nil
    }
    
    func me() async throws -> (String, String) {
        let request = APIRequest<MeResponse>(path: "api/me", method: .get, maxAttempts: 4, bypassesOffline: true)
        let response = try await response(request)
        return (response.id, response.username)
    }
    
    func authorize() async throws -> ([ProgressPayload], [BookmarkPayload]) {
        let request = APIRequest<AuthorizationResponse>(path: "api/authorize", method: .post, bypassesOffline: true, bypassesScheduler: true)
        let response = try await response(request)
        return (response.user.mediaProgress, response.user.bookmarks)
    }
    func refresh(refreshToken: String) async throws -> (String, String?) {
        let response = try await response(APIRequest<AuthorizationResponse>(
            path: "auth/refresh",
            method: .post,
            headers: ["x-refresh-token": refreshToken],
            bypassesOffline: true,
            bypassesScheduler: true,
        ))
        return try (response.versionSafeAccessToken, response.versionSafeRefreshToken)
    }
}

public extension APIClient {
    func openIDLoginURL(verifier: String) async throws -> URL {
        clearCookies()
        
        var challenge = Data(verifier.compactMap { $0.asciiValue }).sha256.base64EncodedString()
        
        // Base64 --> URL-Base64
        challenge = challenge.replacingOccurrences(of: "+", with: "-")
        challenge = challenge.replacingOccurrences(of: "/", with: "_")
        challenge = challenge.replacingOccurrences(of: "=", with: "")
        
        let request = try await request(APIRequest<APIClient.EmptyResponse>(
            path: "auth/openid",
            method: .get,
            query: [
                URLQueryItem(name: "client_id", value: "ShelfPlayer"),
                URLQueryItem(name: "redirect_uri", value: "shelfplayer://callback"),
                URLQueryItem(name: "code_challenge_method", value: "S256"),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "code_challenge", value: "\(challenge)")
            ],
        ))
        let (_, response) = try await session.data(for: request)
        
        if let location = (response as? HTTPURLResponse)?.allHeaderFields["Location"] as? String, let url = URL(string: location) {
            return url
        }
        
        throw APIClientError.notFound
    }
    
    func openIDExchange(code: String, state: String, verifier: String) async throws -> (username: String, accessToken: String, refreshToken: String?) {
        let request = APIRequest<AuthorizationResponse>(
            path: "auth/openid/callback",
            method: .get,
            query: [
                .init(name: "code", value: code),
                .init(name: "state", value: state),
                .init(name: "code_verifier", value: verifier)
            ],
            bypassesOffline: true,
            bypassesScheduler: true,
        )
        
        let response = try await response(request)
        
        return try (response.user.username, response.versionSafeAccessToken, response.versionSafeRefreshToken)
    }
}
