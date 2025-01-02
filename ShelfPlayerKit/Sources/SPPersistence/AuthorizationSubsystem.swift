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
import SPFoundation
import RFNetwork

typealias DiscoveredServer = SchemaV2.PersistedDiscoveredServer

public let ABSClient = APIClientStore { serverID in
    guard let server = PersistenceManager.shared.authorization[serverID] else {
        throw PersistenceError.serverNotFound
    }
    
    let authorizationHeader = HTTPHeader(key: "Authorization", value: "Bearer \(server.token)")
    
    return (server.host, server.headers + [authorizationHeader])
}

extension PersistenceManager {
    @ModelActor
    public final actor AuthorizationSubsystem: Sendable {
        private let service = "io.rfk.shelfPlayer.credentials".data(using: .ascii)!
        private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Authorization")
        
        var servers = [ItemIdentifier.ServerID: Server]()
        
        public struct Server: Identifiable, Sendable, Hashable, Codable {
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
            
            public var id: ItemIdentifier.ServerID {
                // If someone has this as their user- or hostname its honestly their fault. This wont event break...
                SHA256.hash(data: "host:\(host).?.?.user:\(user)".data(using: .ascii)!).withUnsafeBytes {
                    Data([UInt8]($0))
                }.base64EncodedString()
            }
        }
        
        public struct KnownServer: Sendable, Identifiable, Equatable {
            public let id = UUID()
            
            public let host: URL
            public let username: String
        }
        
        func retrieveServers() throws {
            let query = [
                kSecAttrService: service,
                kSecClass: kSecClassGenericPassword,
                
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitAll,
            ] as! [String: Any] as CFDictionary
            
            var items: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &items)
            
            guard status == errSecSuccess, let items = items as? [[String: Any]] else {
                logger.fault("Error retrieving servers from keychain: \(status).")
                throw PersistenceError.keychainRetrieveFailed
            }
            
            for item in items {
                do {
                    let data = item[kSecValueData as String] as? Data
                    
                    guard let data else {
                        logger.fault("Error retrieving server data from keychain.")
                        continue
                    }
                    
                    let server = try JSONDecoder().decode(Server.self, from: data)
                    servers[server.id] = server
                } catch {
                    logger.fault("Error decoding server from keychain: \(error).")
                    continue
                }
            }
        }
    }
}

public extension PersistenceManager.AuthorizationSubsystem {
    var knownServers: [KnownServer] {
        get async {
            var descriptor = FetchDescriptor<DiscoveredServer>()
            descriptor.fetchLimit = 100
            
            do {
                return try modelContext.fetch(descriptor).map { .init(host: $0.host, username: $0.user) }
            } catch {
                return []
            }
        }
    }
    
    func addServer(_ server: Server) throws {
        let descriptor = FetchDescriptor<DiscoveredServer>(predicate: #Predicate { $0.serverID == server.id })
        let count = try? modelContext.fetchCount(descriptor)
        
        if let count, count == 0 {
            let discovered = DiscoveredServer(serverID: server.id, host: server.host, user: server.user)
            
            modelContext.insert(discovered)
            try modelContext.save()
        }
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrSynchronizable: true,
            
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            
            kSecAttrAccount: server.id,
            kSecValueData: try JSONEncoder().encode(server)
        ] as! [String: Any] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        
        guard status == errSecSuccess else {
            logger.error("Error adding server to keychain: \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainInsertFailed
        }
    }
    
    subscript(_ id: ItemIdentifier.ServerID) -> Server? {
        servers[id]
    }
}
