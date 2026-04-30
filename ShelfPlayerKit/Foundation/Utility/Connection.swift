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

    let permissions: UserPermissionsPayload?

    init(host: URL, user: String, headers: [HTTPHeader], added: Date, permissions: UserPermissionsPayload? = nil) {
        self.host = host
        self.user = user
        self.headers = headers
        self.added = added
        self.permissions = permissions
    }

    var connectionID: ItemIdentifier.ConnectionID {
        SHA256.hash(data: "host:\(host).?.?.user:\(user)".data(using: .utf8)!).withUnsafeBytes {
            Data([UInt8]($0))
        }.base64EncodedString()
    }

    var id: ItemIdentifier.ConnectionID {
        connectionID
    }
    var friendlyName: String {
        "\(host.formatted(.url.host())): \(user)"
    }

    func with(permissions: UserPermissionsPayload?) -> Connection {
        Connection(host: host, user: user, headers: headers, added: added, permissions: permissions)
    }
}

public struct FriendlyConnection: Codable, Sendable, Identifiable {
    public let id: ItemIdentifier.ConnectionID
    public let name: String

    public let host: URL
    public let username: String

    public let permissions: UserPermissionsPayload?

    init(from connection: Connection) {
        id = connection.id
        name = connection.friendlyName

        host = connection.host
        username = connection.user

        permissions = connection.permissions
    }

    #if DEBUG
    private init(id: ItemIdentifier.ConnectionID, name: String, host: URL, username: String, permissions: UserPermissionsPayload?) {
        self.id = id
        self.name = name
        self.host = host
        self.username = username
        self.permissions = permissions
    }

    public static let fixture = FriendlyConnection(id: "fixture", name: "Fixture", host: .temporaryDirectory, username: "Fixture", permissions: nil)
    #endif
}
