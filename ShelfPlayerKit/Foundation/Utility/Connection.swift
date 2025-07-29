//
//  Connection.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import CryptoKit

struct Connection: Identifiable, Sendable, Hashable, Codable {
    let host: URL
    let user: String
    
    let refreshToken: String
    let headers: [HTTPHeader]
    
    var connectionID: ItemIdentifier.ConnectionID {
        SHA256.hash(data: "host:\(host).?.?.user:\(user)".data(using: .ascii)!).withUnsafeBytes {
            Data([UInt8]($0))
        }.base64EncodedString()
    }
    
    public init(host: URL, user: String, refreshToken: String, headers: [HTTPHeader]) {
        self.host = host
        self.user = user
        self.refreshToken = refreshToken
        
        self.headers = headers
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.host = try container.decode(URL.self, forKey: .host)
        self.user = try container.decode(String.self, forKey: .user)
        self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
        
        self.headers = try container.decode([HTTPHeader].self, forKey: .headers)
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.host, forKey: .host)
        try container.encode(self.user, forKey: .user)
        try container.encode(self.refreshToken, forKey: .refreshToken)
        
        try container.encode(self.headers, forKey: .headers)
    }
    
    enum CodingKeys: CodingKey {
        case host
        case user
        
        case refreshToken
        case headers
    }
    
    public var id: ItemIdentifier.ConnectionID {
        connectionID
    }
    public var friendlyName: String {
        "\(host.formatted(.url.host())): \(user)"
    }
}

public struct FriendlyConnection: Codable, Sendable, Identifiable {
    public let id: ItemIdentifier.ConnectionID
    public let name: String
    
    public let host: URL
    
    init(from connection: Connection) {
        id = connection.id
        name = connection.friendlyName
        host = connection.host
    }
}
