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
    
    let headers: [HTTPHeader]
    let added: Date
    
    var connectionID: ItemIdentifier.ConnectionID {
        SHA256.hash(data: "host:\(host).?.?.user:\(user)".data(using: .ascii)!).withUnsafeBytes {
            Data([UInt8]($0))
        }.base64EncodedString()
    }
    
    public init(host: URL, user: String, headers: [HTTPHeader], added: Date) {
        self.host = host
        self.user = user
        
        self.headers = headers
        self.added = added
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.host = try container.decode(URL.self, forKey: .host)
        self.user = try container.decode(String.self, forKey: .user)
        
        self.headers = try container.decode([HTTPHeader].self, forKey: .headers)
        self.added = try container.decode(Date.self, forKey: .added)
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.host, forKey: .host)
        try container.encode(self.user, forKey: .user)
        
        try container.encode(self.headers, forKey: .headers)
        try container.encode(self.added, forKey: .added)
    }
    
    enum CodingKeys: CodingKey {
        case host
        case user
        
        case headers
        case added
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
    public let username: String
    
    init(from connection: Connection) {
        id = connection.id
        name = connection.friendlyName
        
        host = connection.host
        username = connection.user
    }
    #if DEBUG
    private init(id: ItemIdentifier.ConnectionID, name: String, host: URL, username: String) {
        self.id = id
        self.name = name
        self.host = host
        self.username = username
    }
    
    public static let fixture = FriendlyConnection(id: "fixture", name: "Fixture", host: .temporaryDirectory, username: "Fixture")
    #endif
}
