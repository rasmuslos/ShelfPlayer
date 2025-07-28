//
//  APIClient.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation
@preconcurrency import Security
import OSLog

public actor APIClient {
    let logger: Logger
    let verbose = false
    
    let connectionID: ItemIdentifier.ConnectionID
    
    let session: URLSession
    let host: URL
    
    public internal(set) var headers: [HTTPHeader]
    var identity: SecIdentity?
    
    let credentialProvider: APICredentialProvider
    var sessionToken: String?
    
    public init(connectionID: ItemIdentifier.ConnectionID, credentialProvider: APICredentialProvider) async throws {
        logger = .init(subsystem: "io.rfk.shelfPlayerKit", category: "APIClient::\(connectionID)")
        
        self.connectionID = connectionID
        
        let configuration = URLSessionConfiguration.ephemeral
        
        configuration.httpCookieStorage = ShelfPlayerKit.httpCookieStorage
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .onlyFromMainDocumentDomain
        
        session = URLSession.init(configuration: configuration, delegate: URLSessionDelegate(), delegateQueue: nil)
        session.sessionDescription = "ShelfPlayer APIClient::\(connectionID)"
        
        (host, headers, identity) = try await credentialProvider.configuration
        
        self.credentialProvider = credentialProvider
        sessionToken = try await credentialProvider.requestSessionToken(refresh: false)
    }
    
    func request(path: String, method: HTTPMethod, body: Any?, query: [URLQueryItem]?) async throws -> URLRequest {
        var url = host.appending(path: path)
        
        if let query {
            url.append(queryItems: query)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.value
        request.httpShouldHandleCookies = true
        request.timeoutInterval = 120
        
        for pair in headers {
            request.addValue(pair.value, forHTTPHeaderField: pair.key)
        }
        
        if let sessionToken {
            request.addValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }
        
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
    
    func response(request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                fatalError("401")
            } else if !(200..<299).contains(httpResponse.statusCode) {
                throw APIClientError.invalidResponseCode
            }
        }
        
        if verbose {
            logger.debug("\(request.url?.relativePath ?? "?", privacy: .public) \(request.httpMethod ?? "?", privacy: .public) < \(String.init(data: data, encoding: .utf8)!, privacy: .public)")
        }
        
        return data
    }
    func response<R: Decodable>(request: URLRequest) async throws -> R {
        do {
            let data = try await response(request: request)
            return try JSONDecoder().decode(R.self, from: data)
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

private extension APIClient {
    final class URLSessionDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
            guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
                return (.performDefaultHandling, nil)
            }
            
            // TODO: Provide Identity
            
            return (.performDefaultHandling, nil)
        }
        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
            if let path = task.originalRequest?.url?.pathComponents, path.count >= 2 && path[0] == "auth" && path[1] == "openid" {
                nil
            } else {
                request
            }
        }
    }
    
    func refreshSessionToken() async {
        
    }
}
