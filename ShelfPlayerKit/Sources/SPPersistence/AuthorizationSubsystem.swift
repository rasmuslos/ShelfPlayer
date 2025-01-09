//
//  AuthorizationSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import OSLog
import CryptoKit
import SwiftData
import RFNetwork
import RFNotifications
import SPFoundation

typealias DiscoveredConnection = SchemaV2.PersistedDiscoveredConnection

public let ABSClient = APIClientStore { connectionID in
    guard let connection = PersistenceManager.shared.authorization[connectionID] else {
        throw PersistenceError.serverNotFound
    }
    
    let authorizationHeader = HTTPHeader(key: "Authorization", value: "Bearer \(connection.token)")
    
    return (connection.host, connection.headers + [authorizationHeader])
}

extension PersistenceManager {
    @ModelActor
    public final actor AuthorizationSubsystem: Sendable {
        private let service = "io.rfk.shelfPlayer.credentials" as CFString
        private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Authorization")
        
        private(set) public var connections = [ItemIdentifier.ConnectionID: Connection]()
        
        public struct Connection: Identifiable, Sendable, Hashable, Codable {
            public let host: URL
            public let user: String
            public let token: String
            public let headers: [HTTPHeader]
            
            public init(host: URL, user: String, token: String, headers: [HTTPHeader]) {
                self.host = host
                self.user = user
                self.token = token
                self.headers = headers
            }
            
            public var id: ItemIdentifier.ConnectionID {
                // If someone has this as their user- or hostname its honestly their fault. This wont event break...
                SHA256.hash(data: "host:\(host).?.?.user:\(user)".data(using: .ascii)!).withUnsafeBytes {
                    Data([UInt8]($0))
                }.base64EncodedString()
            }
        }
        
        public struct KnownConnection: Sendable, Identifiable, Equatable {
            public let id: String
            
            public let host: URL
            public let username: String
        }
    }
}

public extension PersistenceManager.AuthorizationSubsystem {
    var knownConnections: [KnownConnection] {
        get async {
            var descriptor = FetchDescriptor<DiscoveredConnection>()
            descriptor.fetchLimit = 100
            
            do {
                return try modelContext.fetch(descriptor).map { .init(id: UUID().uuidString, host: $0.host, username: $0.user) }
            } catch {
                return []
            }
        }
    }
    
    func fetchConnections() throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            
            kSecAttrService: service,
            
            kSecReturnAttributes: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitAll,
        ] as! [String: Any] as CFDictionary
        
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query, &items)
        
        guard status != errSecItemNotFound else {
            logger.info("No connections found in keychain")
            connections.removeAll()
            
            return
        }
        
        guard status == errSecSuccess, let items = items as? [[String: Any]] else {
            logger.error("Error retrieving connections from keychain: \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainRetrieveFailed
        }
        
        for item in items {
            do {
                guard let connectionID = item[kSecAttrAccount as String] as? String else {
                    continue
                }
                
                connections[connectionID] = try fetchConnection(connectionID)
            } catch {
                logger.fault("Error decoding connection from keychain: \(error).")
                continue
            }
        }
        
        RFNotification[.connectionsChanged].send(connections)
    }
    
    func addConnection(_ connection: Connection) throws {
        let descriptor = FetchDescriptor<DiscoveredConnection>(predicate: #Predicate { $0.connectionID == connection.id })
        let count = try? modelContext.fetchCount(descriptor)
        
        if let count, count == 0 {
            let discovered = DiscoveredConnection(connectionID: connection.id, host: connection.host, user: connection.user)
            
            modelContext.insert(discovered)
            try modelContext.save()
        }
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kCFBooleanTrue as Any,
            
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            
            kSecAttrService: service,
            kSecAttrAccount: connection.id as CFString,
            
            kSecValueData: try JSONEncoder().encode(connection) as CFData,
        ] as! [String: Any] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        
        guard status == errSecSuccess else {
            logger.error("Error adding connection to keychain: \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainInsertFailed
        }
        
        try fetchConnections()
    }
    
    func fetchConnection(_ connectionID: ItemIdentifier.ConnectionID) throws -> Connection {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            
            kSecAttrService: service,
            kSecAttrAccount: connectionID,
            
            kSecReturnData: kCFBooleanTrue as Any,
        ]
        
        var data: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &data)
        
        guard status == errSecSuccess, let data = data as? Data else {
            logger.fault("Error retrieving connection data from keychain: \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainRetrieveFailed
        }
        
        return try JSONDecoder().decode(Connection.self, from: data)
    }
    
    func updateConnection(_ connectionID: ItemIdentifier.ConnectionID, headers: [HTTPHeader]) throws {
        let connection = try fetchConnection(connectionID)
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kCFBooleanTrue as Any,
            
            kSecAttrService: service,
            kSecAttrAccount: connectionID as CFString,
        ] as! [String: Any] as CFDictionary
        
        let updated = Connection(host: connection.host, user: connection.user, token: connection.token, headers: headers)
        
        SecItemUpdate(query, [
            kSecValueData: try JSONEncoder().encode(updated) as CFData,
        ] as! [String: Any] as CFDictionary)
        
        try fetchConnections()
    }
    
    func removeConnection(_ connectionID: ItemIdentifier.ConnectionID) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            
            kSecAttrService: service,
            kSecAttrAccount: connectionID,
        ] as! [String: Any] as CFDictionary
        
        let status = SecItemDelete(query)
        
        guard status == errSecSuccess else {
            logger.error("Error removing connection from keychain: \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainInsertFailed
        }
        
        try fetchConnections()
    }
    
    func reset() throws {
        SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
        ] as CFDictionary)
        
        try modelContext.delete(model: DiscoveredConnection.self)
        try fetchConnections()
    }
    
    subscript(_ id: ItemIdentifier.ConnectionID) -> Connection? {
        connections[id]
    }
}

extension RFNotification.Notification {
    public static var connectionsChanged: Notification<[ItemIdentifier.ConnectionID: PersistenceManager.AuthorizationSubsystem.Connection]> {
        .init("io.rfk.ShelfPlayer.connectionsChanged")
    }
}
