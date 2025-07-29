//
//  AudiobookshelfClient+Authorization.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

public extension APIClient {
    func login(username: String, password: String) async throws -> (username: String, accessToken: String, refreshToken: String) {
        var request = try await request(path: "login", method: .post, body: [
            "username": username,
            "password": password,
        ], query: nil)
        
        request.setValue("true", forHTTPHeaderField: "x-return-tokens")
        
        let response: AuthorizationResponse = try await response(request: request)
        
        return (response.user.username, response.user.accessToken!, response.user.refreshToken!)
    }
    
    func status() async throws -> StatusResponse {
        try await response(path: "status", method: .get)
    }
    
    func me() async throws -> (String, String) {
        let response: MeResponse = try await response(path: "api/me", method: .get)
        return (response.id, response.username)
    }
    
    func authorize() async throws -> ([ProgressPayload], [BookmarkPayload]) {
        let response: AuthorizationResponse = try await response(path: "api/authorize", method: .post)
        return (response.user.mediaProgress, response.user.bookmarks)
    }
}

public extension APIClient {
    private final class URLSessionDelegate: NSObject, URLSessionTaskDelegate {
        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
            nil
        }
    }
    
    func openIDLoginURL(verifier: String) async throws -> URL {
        clearCookies()
        
        var challenge = Data(verifier.compactMap { $0.asciiValue }).sha256.base64EncodedString()
        
        // Base64 --> URL-Base64
        challenge = challenge.replacingOccurrences(of: "+", with: "-")
        challenge = challenge.replacingOccurrences(of: "/", with: "_")
        challenge = challenge.replacingOccurrences(of: "=", with: "")
        
        let request = try await request(path: "auth/openid", method: .get, body: nil, query: [
            URLQueryItem(name: "client_id", value: "ShelfPlayer"),
            URLQueryItem(name: "redirect_uri", value: "shelfplayer://callback"),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: "\(challenge)"),
        ])
        
        let (_, response) = try await session.data(for: request)
        
        if let location = (response as? HTTPURLResponse)?.allHeaderFields["Location"] as? String, let url = URL(string: location) {
            return url
        }
        
        throw APIClientError.notFound
    }
    
    func openIDExchange(code: String, state: String, verifier: String) async throws -> (username: String, accessToken: String, refreshToken: String) {
        let response: AuthorizationResponse = try await response(path: "auth/openid/callback", method: .get, query: [
            .init(name: "code", value: code),
            .init(name: "state", value: state),
            .init(name: "code_verifier", value: verifier),
        ])
        
        return (response.user.username, response.user.accessToken!, response.user.refreshToken!)
    }
}
