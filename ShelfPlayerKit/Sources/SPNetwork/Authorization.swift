//
//  AudiobookshelfClient+Authorization.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient {
    func login(username: String, password: String) async throws -> String {
        let response = try await response(for: ClientRequest<AuthorizationResponse>(path: "login", method: .post, body: [
            "username": username,
            "password": password,
        ]))
        
        return response.user.token
    }
    
    func status() async throws -> StatusResponse {
        try await response(for: ClientRequest<StatusResponse>(path: "status", method: .get))
    }
    
    func me() async throws -> (String, String) {
        let response = try await response(for: ClientRequest<MeResponse>(path: "api/me", method: .get))
        return (response.id, response.username)
    }
    
    func authorize() async throws -> ([ProgressPayload], [BookmarkPayload]) {
        let response = try await response(for: ClientRequest<AuthorizationResponse>(path: "api/authorize", method: .post))
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
        var challenge = Data(verifier.compactMap { $0.asciiValue }).sha256.base64EncodedString()
        
        // Base64 --> URL-Base64
        challenge = challenge.replacingOccurrences(of: "+", with: "-")
        challenge = challenge.replacingOccurrences(of: "/", with: "_")
        challenge = challenge.replacingOccurrences(of: "=", with: "")
        
        let url = URL(string: host.appending(path: "auth").appending(path: "openid").appending(queryItems: [
            URLQueryItem(name: "client_id", value: "ShelfPlayer"),
            URLQueryItem(name: "redirect_uri", value: "shelfplayer://callback"),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "response_type", value: "code"),
        ]).absoluteString.appending("&code_challenge=\(challenge)"))!
        
        for cookie in HTTPCookieStorage.shared.cookies(for: url) ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        let session = URLSession(configuration: .default, delegate: URLSessionDelegate(), delegateQueue: nil)
        var request = URLRequest(url: url)
        
        request.httpShouldHandleCookies = true
        request.httpMethod = "GET"
        
        for pair in headers {
            request.addValue(pair.value, forHTTPHeaderField: pair.key)
        }
        
        let (_, response) = try await session.data(for: request)
        if let location = (response as? HTTPURLResponse)?.allHeaderFields["Location"] as? String, let url = URL(string: location) {
            return url
        }
        
        throw APIClientError.invalidResponse
    }
    
    func openIDExchange(code: String, state: String, verifier: String) async throws -> String {
        let response = try await response(for: ClientRequest<AuthorizationResponse>(path: "auth/openid/callback", method: .get, query: [
            .init(name: "code", value: code),
            .init(name: "state", value: state),
            .init(name: "code_verifier", value: verifier),
        ]))
        
        return response.user.token
    }
}
