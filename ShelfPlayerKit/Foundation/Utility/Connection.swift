//
//  Connection.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import CryptoKit
import RFNetwork

public struct Connection: Identifiable, Sendable, Hashable, Codable {
    public let host: URL
    public let user: String
    public let token: String
    public let headers: [HTTPHeader]
    
    private var connectionID: ItemIdentifier.ConnectionID!
    
    public init(host: URL, user: String, token: String, headers: [HTTPHeader]) {
        self.host = host
        self.user = user
        self.token = token
        self.headers = headers
        
        self.createConnectionID()
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.host = try container.decode(URL.self, forKey: .host)
        self.user = try container.decode(String.self, forKey: .user)
        self.token = try container.decode(String.self, forKey: .token)
        self.headers = try container.decode([HTTPHeader].self, forKey: .headers)
        
        self.createConnectionID()
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.host, forKey: .host)
        try container.encode(self.user, forKey: .user)
        try container.encode(self.token, forKey: .token)
        try container.encode(self.headers, forKey: .headers)
    }
    
    enum CodingKeys: CodingKey {
        case host
        case user
        case token
        case headers
    }
    
    public var id: ItemIdentifier.ConnectionID {
        connectionID
    }
    public var friendlyName: String {
        "\(host.formatted(.url.host())): \(user)"
    }
    
    private mutating func createConnectionID() {
        connectionID = SHA256.hash(data: "host:\(host).?.?.user:\(user)".data(using: .ascii)!).withUnsafeBytes {
            Data([UInt8]($0))
        }.base64EncodedString()
    }
}
