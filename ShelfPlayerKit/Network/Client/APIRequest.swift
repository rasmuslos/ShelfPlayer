//
//  APIRequest.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.12.25.
//

import Foundation
import CryptoKit

public struct APIRequest<R: Decodable>: APIRequestProtocol, @unchecked Sendable {
    public let path: String
    public let method: HTTPMethod
    
    public let body: Any?
    public let query: [URLQueryItem]
    public let headers: [String: String]
    
    public let ttl: TimeInterval?
    public let timeout: TimeInterval
    public let maxAttempts: Int
    public let bypassesOffline: Bool
    public let bypassesScheduler: Bool
    
    public let dataBody: Data?
    
    public let id: String
    public let description: String
    
    public init(path: String, method: HTTPMethod, body: Any? = nil, query: [URLQueryItem] = [], headers: [String: String] = [:], ttl: TimeInterval? = nil, timeout: TimeInterval = 45, maxAttempts: Int = 3, bypassesOffline: Bool = false, bypassesScheduler: Bool = false) {
        self.path = path
        self.method = method
        
        self.body = body
        self.query = query
        self.headers = headers
        
        self.ttl = ttl
        self.timeout = timeout
        self.maxAttempts = maxAttempts
        
        self.bypassesOffline = bypassesOffline
        self.bypassesScheduler = bypassesScheduler
        
        if let body {
            if let encodable = body as? Encodable {
                dataBody = try? JSONEncoder().encode(encodable)
            } else {
                dataBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            }
        } else {
            dataBody = nil
        }
        
        let bodyDescription: String
        
        if let dataBody, let description = String(data: dataBody, encoding: .utf8) {
            bodyDescription = description
        } else {
            bodyDescription = "-"
        }
        
        description = """
        API-Request:
        \(URL(string: "s://0/")!.appending(path: path).appending(queryItems: query).absoluteString)
        Method: \(method)
        Body: \(bodyDescription)
        TTL: \(ttl?.description ?? "nil")
        Timeout: \(timeout)
        Max Attempts: \(self.maxAttempts)
        Bypasses Offline: \(bypassesOffline)
        Bypasses Scheduler: \(bypassesScheduler)
        """
        
        let digest = SHA256.hash(data: Data(description.utf8))
        id = digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(path)
        hasher.combine(method)
        hasher.combine(String(describing: body))
        hasher.combine(query)
        hasher.combine(ttl)
        hasher.combine(timeout)
        hasher.combine(maxAttempts)
        hasher.combine(bypassesOffline)
        hasher.combine(bypassesScheduler)
    }
    public static func == (lhs: APIRequest<R>, rhs: APIRequest<R>) -> Bool {
        lhs.id == rhs.id
    }
    
    public func _typecast(_ data: Data) throws -> R {
        try JSONDecoder().decode(R.self, from: data)
    }
    public func typecast(decodable: any Decodable) throws -> R {
        guard let type = decodable as? R else {
            throw APIClientError.serializeError
        }
        
        return type
    }
}

public extension APIClient {
    struct DataResponse: Decodable, Sendable {
        public let data: Data
    }
    struct EmptyResponse: Decodable, Sendable {
    }
}
