//
//  AuthorizationSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import Security
import CryptoKit
import SwiftData
import OSLog
import RFNotifications

typealias DiscoveredConnection = SchemaV2.PersistedDiscoveredConnection

extension PersistenceManager {
    @ModelActor
    public final actor AuthorizationSubsystem: Sendable {
        private let connectionService = "io.rfk.shelfPlayer.credentials.v2" as CFString
        private let tlsCertificateService = "io.rfk.shelfPlayer.credentials.tlsCertificate" as CFString
        
        private let accessTokenService = "io.rfk.shelfPlayer.credentials.accessToken" as CFString
        private let refreshTokenService = "io.rfk.shelfPlayer.credentials.refreshToken" as CFString
        
        private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Authorization")
        
        public private(set) var connectionIDs = [ItemIdentifier.ConnectionID]()
        // Don't store refresh tokens in RAM unless necessary
        public private(set) var friendlyConnections = [FriendlyConnection]()
        
        public struct KnownConnection: Sendable, Identifiable, Equatable {
            public let id: String
            
            public let host: URL
            public let username: String
        }
    }
}

public extension PersistenceManager.AuthorizationSubsystem {
    // MARK: Getter
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
    
    func host(for connectionID: ItemIdentifier.ConnectionID) throws -> URL {
        guard let connection = friendlyConnections.first(where: { $0.id == connectionID }) else {
            throw APIClientError.notFound
        }
        
        return connection.host
    }
    func headers(for connectionID: ItemIdentifier.ConnectionID) throws -> [HTTPHeader] {
        /*
        guard let connection = connections.first(where: { $0.id == connectionID }) else {
            throw APIClientError.notFound
        }
        
        return connection.headers
         */
        []
    }
    func configuration(for connectionID: ItemIdentifier.ConnectionID) throws -> (URL, [HTTPHeader]) {
        let connection = try fetchConnection(connectionID)
        return (connection.host, connection.headers)
    }
    
    // MARK: Modify
    
    func addConnection(host: URL, username: String, headers: [HTTPHeader], identity: SecIdentity?, accessToken: String, refreshToken: String) throws {
        let connection = Connection(host: host, user: username, headers: headers, added: .now)
        
        do {
            let discovered = DiscoveredConnection(connectionID: connection.connectionID, host: connection.host, user: connection.user)
            
            modelContext.insert(discovered)
            try modelContext.save()
        } catch {
            logger.error("Failed to save discovered connection: \(error)")
        }
        
        // Connection
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kCFBooleanTrue as Any,
            
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            
            kSecAttrService: connectionService,
            kSecAttrAccount: connection.id as CFString,
            
            kSecValueData: try JSONEncoder().encode(connection) as CFData,
        ] as! [String: Any] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        
        guard status == errSecSuccess else {
            logger.error("Error adding connection to keychain: \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainInsertFailed
        }
        
        // TLS Certificate
        
        if let identity {
            let query = [
                kSecClass: kSecClassIdentity,
                kSecAttrSynchronizable: kCFBooleanTrue as Any,
                
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                
                kSecAttrService: tlsCertificateService,
                kSecAttrAccount: connection.id as CFString,
                
                kSecValueRef: identity,
            ] as! [String: Any] as CFDictionary
            
            let status = SecItemAdd(query, nil)
            
            guard status == errSecSuccess else {
                logger.error("Error adding tls certificate to keychain for \(connection.id): \(SecCopyErrorMessageString(status, nil))")
                throw PersistenceError.keychainInsertFailed
            }
        }
        
        // Access Token
        
        try storeToken(accessToken, forConnectionID: connection.id, service: accessTokenService)
        try storeToken(refreshToken, forConnectionID: connection.id, service: refreshTokenService)
        
        // Update
        
        try fetchConnections()
    }
    
    func updateConnection(_ connectionID: ItemIdentifier.ConnectionID, headers: [HTTPHeader]) throws {
        /*
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
        
        Task {
            await ABSClient.invalidate(connectionID)
        }
        
        try fetchConnections()
         */
    }
    
    func remove(connectionID: ItemIdentifier.ConnectionID) {
        let identityDeleteQuery = [
            kSecClass: kSecClassIdentity,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            
            kSecAttrAccount: connectionID,
        ] as! [String: Any] as CFDictionary
        let genericPasswordDeleteQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            
            kSecAttrAccount: connectionID,
        ] as! [String: Any] as CFDictionary
        
        let identityStatus = SecItemDelete(identityDeleteQuery)
        let passwordStatus = SecItemDelete(genericPasswordDeleteQuery)
        
        // identity may not exist
        if passwordStatus != errSecSuccess {
            logger.error("Error removing connection from keychain: \(SecCopyErrorMessageString(identityStatus, nil)) & \(SecCopyErrorMessageString(passwordStatus, nil))")
        }
        
        try? fetchConnections()
    }
    
    // MARK: Utility
    
    func waitForConnections() async throws {
        guard connectionIDs.isEmpty else {
            return
        }
        
        try fetchConnections()
    }
    
    func handleURLSessionChallenge(_ challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
            return (.performDefaultHandling, nil)
        }
        
        // TODO: Provide Identity
        
        return (.performDefaultHandling, nil)
    }
    
    func reset() async {
        for connectionID in connectionIDs {
            await PersistenceManager.shared.remove(connectionID: connectionID)
        }
        
        SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
        ] as CFDictionary)
        
        do {
            try modelContext.delete(model: DiscoveredConnection.self)
            try modelContext.save()
            
            try fetchConnections()
        } catch {
            logger.error("Failed to reset authorization subsystem: \(error)")
        }
    }
    
    #if DEBUG
    func scrambleAccessToken(connectionID: ItemIdentifier.ConnectionID) throws {
        try updateToken("bazinga", for: connectionID, service: accessTokenService)
        try fetchConnections()
    }
    #endif
}

extension PersistenceManager.AuthorizationSubsystem {
    // MARK: Fetch
    
    func fetchConnection(_ connectionID: ItemIdentifier.ConnectionID) throws -> Connection {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            
            kSecAttrService: connectionService,
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
    func fetchConnections() throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            
            kSecAttrService: connectionService,
            
            kSecReturnAttributes: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitAll,
        ] as! [String: Any] as CFDictionary
        
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query, &items)
        
        guard status != errSecItemNotFound else {
            logger.info("No connections found in keychain")
            
            if !connectionIDs.isEmpty {
                updateConnections([])
                RFNotification[.connectionsChanged].dispatch()
            }
            
            return
        }
        
        guard status == errSecSuccess, let items = items as? [[String: Any]] else {
            logger.error("Error retrieving connections from keychain: \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainRetrieveFailed
        }
        
        var connections = [Connection]()
        
        for item in items {
            do {
                guard let connectionID = item[kSecAttrAccount as String] as? String else {
                    continue
                }
                
                try connections.append(fetchConnection(connectionID))
            } catch {
                logger.fault("Error decoding connection from keychain: \(error).")
                continue
            }
        }
        
        updateConnections(connections)
        
        RFNotification[.connectionsChanged].dispatch()
    }
    
    // MARK: Token
    
    func accessToken(for connectionID: String) throws -> String {
        try token(for: connectionID, service: accessTokenService)
    }
    func refreshAccessToken(for connectionID: String) async throws -> String {
        let client = try await APIClient(connectionID: connectionID, credentialProvider: AuthorizedAPIClientCredentialProvider(connectionID: connectionID))
        let (accessToken, refreshToken) = try await client.refresh(refreshToken: token(for: connectionID, service: refreshTokenService))
        
        try updateToken(accessToken, for: connectionID, service: accessTokenService)
        try updateToken(refreshToken, for: connectionID, service: refreshTokenService)
        
        return accessToken
    }
}

private extension PersistenceManager.AuthorizationSubsystem {
    func token(for connectionID: String, service: CFString) throws -> String {
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
            logger.fault("Error retrieving token data from keychain \(service): \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainRetrieveFailed
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            logger.fault("Error decoding connection data from keychain \(service): \(data)")
            throw PersistenceError.keychainRetrieveFailed
        }
        
        return string
    }
    func updateToken(_ token: String, for connectionID: String, service: CFString) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            
            kSecAttrService: service,
            kSecAttrAccount: connectionID as CFString,
        ] as! [String: Any] as CFDictionary
        
        let status = SecItemUpdate(query,  [
            kSecValueData: (token.data(using: .utf8) ?? .init()) as CFData,
        ] as! [String: Any] as CFDictionary)
        
        guard status == errSecSuccess else {
            logger.error("Error adding access token to keychain for \(connectionID) & \(service): \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainInsertFailed
        }
    }
    func storeToken(_ token: String, forConnectionID connectionID: String, service: CFString) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kCFBooleanTrue as Any,
            
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            
            kSecAttrService: service,
            kSecAttrAccount: connectionID as CFString,
            
            kSecValueData: token.data(using: .utf8) ?? "",
        ] as! [String: Any] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        
        guard status == errSecSuccess else {
            logger.error("Error adding access token to keychain for \(connectionID) & \(service): \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainInsertFailed
        }
    }
    
    func updateConnections(_ connections: [Connection]) {
        connectionIDs = connections.map(\.id)
        friendlyConnections = connections.map { FriendlyConnection(from: $0) }
    }
}
