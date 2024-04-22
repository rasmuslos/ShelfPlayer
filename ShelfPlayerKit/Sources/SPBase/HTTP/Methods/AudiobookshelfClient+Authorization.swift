//
//  AudiobookshelfClient+Authorization.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation
import CommonCrypto

public extension AudiobookshelfClient {
    func status() async throws -> StatusResponse {
        return try await request(ClientRequest<StatusResponse>(path: "status", method: "GET"))
    }
    
    func login(username: String, password: String) async throws -> String {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "login", method: "POST", body: [
            "username": username,
            "password": password,
        ]))
        
        return response.user.token
    }
    
    func username() async throws -> String {
        let response = try await request(ClientRequest<MeResponse>(path: "api/me", method: "GET"))
        return response.username
    }
    func userId() async throws -> String {
        let response = try await request(ClientRequest<MeResponse>(path: "api/me", method: "GET"))
        return response.id
    }
    
    func authorize() async throws -> ([MediaProgress], [Bookmark]) {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "api/authorize", method: "POST"))
        return (response.user.mediaProgress, response.user.bookmarks)
    }
}

public extension AudiobookshelfClient {
    private func sha256(data : Data) -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    func openIDLoginURL(verifier: String) async throws -> URL {
        var challenge = sha256(data: Data(verifier.compactMap { $0.asciiValue })).base64EncodedString()
        
        // Base64 --> URL-Base64
        challenge = challenge.replacingOccurrences(of: "+", with: "-")
        challenge = challenge.replacingOccurrences(of: "/", with: "_")
        challenge = challenge.replacingOccurrences(of: "=", with: "")
        
        let url = URL(string: AudiobookshelfClient.shared.serverUrl.appending(path: "auth").appending(path: "openid").appending(queryItems: [
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
        
        for pair in customHTTPHeaders {
            request.addValue(pair.value, forHTTPHeaderField: pair.key)
        }
        
        let (_, response) = try await session.data(for: request)
        if let location = (response as? HTTPURLResponse)?.allHeaderFields["Location"] as? String, let url = URL(string: location) {
            return url
        }
        
        throw AudiobookshelfClientError.invalidResponse
    }
    
    func openIDExchange(code: String, state: String, verifier: String) async throws -> String {
        let response = try await request(ClientRequest<AuthorizationResponse>(path: "auth/openid/callback", method: "GET", query: [
            .init(name: "code", value: code),
            .init(name: "state", value: state),
            .init(name: "code_verifier", value: verifier),
        ]))
        
        return response.user.token
    }
    
    final class URLSessionDelegate: NSObject, URLSessionTaskDelegate {
        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
            nil
        }
    }
}
