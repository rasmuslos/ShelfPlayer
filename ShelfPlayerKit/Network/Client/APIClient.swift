//
//  APIClient.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation
@preconcurrency import Security
import OSLog

public final class APIClient: Sendable {
    let logger: Logger
    let verbose = false
    
    let connectionID: ItemIdentifier.ConnectionID
    let credentialProvider: APICredentialProvider
    
    let session: URLSession
    
    let host: URL
    let headers: [HTTPHeader]
    
    @MainActor
    var accessToken: String?
    
    @MainActor
    private var isRefreshingAccessToken = false
    
    public init(connectionID: ItemIdentifier.ConnectionID, credentialProvider: APICredentialProvider) async throws {
        logger = .init(subsystem: "io.rfk.shelfPlayerKit", category: "APIClient::\(connectionID)")
        
        self.connectionID = connectionID
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = ShelfPlayerKit.httpCookieStorage
        configuration.urlCache = nil
        
        session = URLSession(configuration: configuration, delegate: URLSessionDelegate(), delegateQueue: nil)
        session.sessionDescription = "ShelfPlayer APIClient::\(connectionID)"
        
        (host, headers) = try await credentialProvider.configuration
        
        self.credentialProvider = credentialProvider
        accessToken = try await credentialProvider.accessToken
    }
    
    func clearCookies() {
        guard let cookies = ShelfPlayerKit.httpCookieStorage.cookies else {
            return
        }

        for cookie in cookies {
            ShelfPlayerKit.httpCookieStorage.deleteCookie(cookie)
        }
    }
    
    func request(path: String, method: HTTPMethod, body: Any?, query: [URLQueryItem]?) async throws -> URLRequest {
        var url = host.appending(path: path)
        
        if let query {
            url.append(queryItems: query)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.value
        request.timeoutInterval = 120
        
        await authorizeRequest(&request)
        
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                if let encodable = body as? Encodable {
                    request.httpBody = try JSONEncoder().encode(encodable)
                } else {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                }
            } catch {
                logger.error("Failed to encode body: \(error, privacy: .public)")
                throw APIClientError.serializeError
            }
        }
        
        if verbose {
            logger.debug("\(path, privacy: .public) \(method.value, privacy: .public) >")
        }
        
        return request
    }
    
    func response(request: URLRequest, didRefreshAccessToken: Bool = false) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                guard !didRefreshAccessToken else {
                    throw APIClientError.unauthorized
                }
                
                try await attemptAccessTokenRefresh(capturedToken: request.value(forHTTPHeaderField: "Authorization")?.replacingOccurrences(of: "Bearer ", with: ""))
                
                var request = request
                
                await authorizeRequest(&request)
                return try await self.response(request: request, didRefreshAccessToken: true)
            } else if !(200..<299).contains(httpResponse.statusCode) {
                logger.error("Got invalid response code \(httpResponse.statusCode)")
                throw APIClientError.invalidResponseCode
            }
        }
        
        if verbose {
            logger.debug("\(request.url?.relativePath ?? "?", privacy: .public) \(request.httpMethod ?? "?", privacy: .public) < \(String.init(data: data, encoding: .utf8)!, privacy: .public)")
        }
        
        return data
    }
    
    public var requestHeaders: [String: String] {
        get async {
            var headers: [String: String] = [:]
            
            for pair in self.headers.sorted(by: { $0.key < $1.key }) {
                headers[pair.key] = pair.value
            }
            
            if let accessToken = await accessToken {
                headers["Authorization"] = "Bearer \(accessToken)"
            }
            
            return headers
        }
    }
    func authorizeRequest(_ request: inout URLRequest) async {
        request.allHTTPHeaderFields?.removeAll()
        
        for (key, value) in await requestHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    func response<R: Decodable>(data: Data) async throws -> R {
        try JSONDecoder().decode(R.self, from: data)
    }
    func response<R: Decodable>(request: URLRequest) async throws -> R {
        do {
            return try await response(data: response(request: request))
        } catch {
            logger.error("Failed to request \(request.url?.relativePath ?? "?", privacy: .public): \(error, privacy: .public)")
            throw APIClientError.parseError
        }
    }
    
    // MARK: Helper
    
    func response(path: String, method: HTTPMethod, body: Any? = nil, query: [URLQueryItem]? = nil) async throws {
        let _ = try await response(request: request(path: path, method: method, body: body, query: query))
    }
    func response<R: Decodable>(path: String, method: HTTPMethod, body: Any? = nil, query: [URLQueryItem]? = nil) async throws -> R {
        try await response(request: request(path: path, method: method, body: body, query: query))
    }
}

extension APIClient {
    final class URLSessionDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
            await PersistenceManager.shared.authorization.handleURLSessionChallenge(challenge)
        }
        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
            if let path = task.originalRequest?.url?.pathComponents, path.count == 3 && path[1] == "auth" && path[2] == "openid" {
                nil
            } else {
                request
            }
        }
    }
    
    func attemptAccessTokenRefresh(capturedToken: String?) async throws {
        var isBlocked = false
        
        repeat {
            isBlocked = await MainActor.run {
                guard !isRefreshingAccessToken else {
                    return true
                }
                
                isRefreshingAccessToken = true
                return false
            }
            
            if isBlocked {
                try await Task.sleep(for: .seconds(0.2))
            }
        } while isBlocked
        
        do {
            let accessToken = try await credentialProvider.refreshAccessToken(current: capturedToken)
            
            await MainActor.run {
                self.accessToken = accessToken
                self.isRefreshingAccessToken = false
            }
        } catch {
            await MainActor.run {
                self.isRefreshingAccessToken = false
            }
        }
    }
}
