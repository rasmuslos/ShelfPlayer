//
//  AuthorizationSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Combine
import Foundation
import Security
import CryptoKit
import SwiftData
import OSLog

typealias DiscoveredConnection = ShelfPlayerSchema.PersistedDiscoveredConnection

extension PersistenceManager {
    @ModelActor
    public final actor AuthorizationSubsystem: Sendable {
        public final class EventSource: @unchecked Sendable {
            public let connectionUnauthorized = PassthroughSubject<ItemIdentifier.ConnectionID, Never>()
            public let connectionsChanged = PassthroughSubject<Void, Never>()
            public let accessTokenExpired = PassthroughSubject<ItemIdentifier.ConnectionID, Never>()

            init() {}
        }

        private let connectionService = "io.rfk.shelfPlayer.credentials.v2" as CFString
        private let tlsCertificateService = "io.rfk.shelfPlayer.credentials.tlsCertificate.v2" as CFString

        private let accessTokenService = "io.rfk.shelfPlayer.credentials.accessToken.v2" as CFString
        private let refreshTokenService = "io.rfk.shelfPlayer.credentials.refreshToken.v2" as CFString

        private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Authorization")
        public nonisolated let events = EventSource()

        public private(set) var connectionIDs = [ItemIdentifier.ConnectionID]()
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
                logger.warning("Failed to fetch known connections: \(error, privacy: .public)")
                return []
            }
        }
    }

    func username(for connectionID: ItemIdentifier.ConnectionID) throws -> String {
        guard let connection = friendlyConnections.first(where: { $0.id == connectionID }) else {
            throw APIClientError.notFound
        }

        return connection.username
    }
    func friendlyName(for connectionID: ItemIdentifier.ConnectionID) throws -> String {
        guard let connection = friendlyConnections.first(where: { $0.id == connectionID }) else {
            throw APIClientError.notFound
        }

        return connection.name
    }

    func host(for connectionID: ItemIdentifier.ConnectionID) throws -> URL {
        guard let connection = friendlyConnections.first(where: { $0.id == connectionID }) else {
            throw APIClientError.notFound
        }

        return connection.host
    }
    func headers(for connectionID: ItemIdentifier.ConnectionID) throws -> [HTTPHeader] {
        try fetchConnection(connectionID).headers
    }
    func configuration(for connectionID: ItemIdentifier.ConnectionID) throws -> (URL, [HTTPHeader]) {
        let connection = try fetchConnection(connectionID)
        return (connection.host, connection.headers)
    }

    func isUsingLegacyAuthentication(for connectionID: ItemIdentifier.ConnectionID) -> Bool {
        (try? token(for: connectionID, service: refreshTokenService)) == nil
    }

    // MARK: Modify

    func addConnection(host: URL, username: String, headers: [HTTPHeader], identity: SecIdentity?, accessToken: String, refreshToken: String?) async throws {
        let connection = Connection(host: host, user: username, headers: headers, added: .now)

        do {
            let discovered = DiscoveredConnection(connectionID: connection.connectionID, host: connection.host, user: connection.user)

            modelContext.insert(discovered)
            try modelContext.save()
        } catch {
            logger.error("Failed to save discovered connection: \(error)")
        }

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

        try storeToken(accessToken, for: connection.id, service: accessTokenService)

        if let refreshToken {
            try storeToken(refreshToken, for: connection.id, service: refreshTokenService)
        }

        await OfflineMode.shared.forceEnable(reason: "Connection added")
        try await fetchConnections()
        await MainActor.run {
            events.connectionsChanged.send()
        }
    }

    func updateConnection(_ connectionID: ItemIdentifier.ConnectionID, headers: [HTTPHeader]) async throws {
        let connection = try fetchConnection(connectionID)

        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kCFBooleanTrue as Any,

            kSecAttrService: connectionService,
            kSecAttrAccount: connectionID as CFString,
        ] as! [String: Any] as CFDictionary

        let updated = Connection(host: connection.host, user: connection.user, headers: headers, added: connection.added)

        SecItemUpdate(query, [
            kSecValueData: try JSONEncoder().encode(updated) as CFData,
        ] as! [String: Any] as CFDictionary)

        await OfflineMode.shared.forceEnable(reason: "Connection updated")
        try await fetchConnections()
        await MainActor.run {
            events.connectionsChanged.send()
        }
    }
    func updateConnection(_ connectionID: ItemIdentifier.ConnectionID, accessToken: String, refreshToken: String?) async throws {
        logger.info("Updating connection with new access token (has refresh token: \(refreshToken != nil))")

        try? removeToken(for: connectionID, service: accessTokenService)
        try storeToken(accessToken, for: connectionID, service: accessTokenService)

        try? removeToken(for: connectionID, service: refreshTokenService)
        if let refreshToken {
            try storeToken(refreshToken, for: connectionID, service: refreshTokenService)
        }

        await OfflineMode.shared.forceEnable(reason: "Connection updated")
        try await fetchConnections()
        await MainActor.run {
            events.connectionsChanged.send()
        }
    }

    func remove(connectionID: ItemIdentifier.ConnectionID) async {
        let identityDeleteQuery = [
            kSecClass: kSecClassIdentity,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,

            kSecAttrAccount: connectionID as CFString,
        ] as! [String: Any] as CFDictionary
        let genericPasswordDeleteQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,

            kSecAttrAccount: connectionID as CFString,
        ] as! [String: Any] as CFDictionary

        let identityStatus = SecItemDelete(identityDeleteQuery)
        let passwordStatus = SecItemDelete(genericPasswordDeleteQuery)

        if passwordStatus != errSecSuccess {
            logger.error("Error removing connection from keychain: \(SecCopyErrorMessageString(identityStatus, nil)) & \(SecCopyErrorMessageString(passwordStatus, nil))")
        }

        await OfflineMode.shared.forceEnable(reason: "Connection removed")
        try? await fetchConnections()
        await MainActor.run {
            events.connectionsChanged.send()
        }
    }

    // MARK: Utility

    func waitForConnections() async throws {
        guard connectionIDs.isEmpty else {
            return
        }

        try await fetchConnections()
    }

    func connectionAvailability(timeout: TimeInterval = OfflineMode.availabilityTimeout) async -> [ItemIdentifier.ConnectionID: Bool] {
        do {
            try await waitForConnections()
        } catch {
            logger.fault("Failed to wait for connections before availability probe: \(error, privacy: .public)")
        }

        let connectionIDs = self.connectionIDs
        let logger = self.logger

        logger.info("Probing connection availability for \(connectionIDs.count, privacy: .public) connection(s) with timeout \(timeout, privacy: .public)s")

        return await withTaskGroup(of: (ItemIdentifier.ConnectionID, Bool).self) {
            for connectionID in connectionIDs {
                $0.addTask {
                    guard let client = try? await ABSClient.client(for: connectionID, ensureAvailabilityEstablished: false) else {
                        logger.warning("Availability probe marked \(connectionID, privacy: .public) offline because API client initialization failed")
                        return (connectionID, false)
                    }

                    let isAvailable = await client.ping(timeout: timeout)
                    logger.info("Availability probe for \(connectionID, privacy: .public) returned \(isAvailable, privacy: .public)")

                    return (connectionID, isAvailable)
                }
            }

            return await $0.reduce(into: [:]) {
                $0[$1.0] = $1.1
            }
        }
    }

    func handleURLSessionChallenge(_ challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
            return (.performDefaultHandling, nil)
        }

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

            try await fetchConnections()
        } catch {
            logger.error("Failed to reset authorization subsystem: \(error)")
        }
    }

    #if DEBUG
    func scrambleAccessToken(connectionID: ItemIdentifier.ConnectionID) async throws {
        try updateToken("bazinga", for: connectionID, service: accessTokenService)
        try await fetchConnections()
    }
    func scrambleRefreshToken(connectionID: ItemIdentifier.ConnectionID) async throws {
        try updateToken("bazinga", for: connectionID, service: refreshTokenService)
        try await fetchConnections()
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
    func fetchConnections() async throws {
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
                await MainActor.run {
                    events.connectionsChanged.send()
                }
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

        guard connections.map(\.id).sorted() != connectionIDs.sorted() else {
            logger.info("No connection updates to propagate")
            return
        }

        updateConnections(connections)
    }

    // MARK: Token

    func accessToken(for connectionID: String) throws -> String {
        try token(for: connectionID, service: accessTokenService)
    }
    func refreshAccessToken(for connectionID: String) async throws -> String {
        logger.info("Refreshing access token for \(connectionID, privacy: .public)")

        guard let currentRefreshToken = try? token(for: connectionID, service: refreshTokenService) else {
            throw APIClientError.unauthorized
        }

        let credentialProvider = try await AuthorizedAPIClientCredentialProvider(connectionID: connectionID, isRefreshProvider: true)
        let client = try await APIClient(connectionID: connectionID, credentialProvider: credentialProvider)

        let (accessToken, refreshToken): (String, String?)

        do {
            (accessToken, refreshToken) = try await client.refresh(refreshToken: currentRefreshToken)
        } catch APIClientError.unauthorized {
            logger.error("Access token refresh for \(connectionID, privacy: .public) failed with an 'unauthorized' error")

            do {
                try removeToken(for: connectionID, service: accessTokenService)
            } catch {
                logger.error("Failed to remove access token for \(connectionID, privacy: .public) after refresh failure: \(error, privacy: .public)")
            }

            do {
                try removeToken(for: connectionID, service: refreshTokenService)
            } catch {
                logger.error("Failed to remove refresh token for \(connectionID, privacy: .public) after refresh failure: \(error, privacy: .public)")
            }

            await MainActor.run {
                events.accessTokenExpired.send(connectionID)
            }

            throw APIClientError.unauthorized
        } catch {
            logger.warning("Access token refresh for \(connectionID, privacy: .public) failed with an unexpected error: \(error)")
            await MainActor.run {
                events.accessTokenExpired.send(connectionID)
            }
            throw APIClientError.offline
        }

        try updateToken(accessToken, for: connectionID, service: accessTokenService)

        if let refreshToken {
            try updateToken(refreshToken, for: connectionID, service: refreshTokenService)
        }

        await MainActor.run {
            events.accessTokenExpired.send(connectionID)
        }

        logger.info("Successfully refreshed access token for \(connectionID, privacy: .public). New refresh token present: \((refreshToken != nil), privacy: .public)")

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
            logger.fault("Error retrieving token data from keychain \(service, privacy: .public): \(SecCopyErrorMessageString(status, nil), privacy: .public) (\(status, privacy: .public))")
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
            kSecAttrSynchronizable: kCFBooleanFalse as Any,

            kSecAttrService: service,
            kSecAttrAccount: connectionID as CFString,
        ] as! [String: Any] as CFDictionary

        let status = SecItemUpdate(query, [
            kSecValueData: (token.data(using: .utf8) ?? .init()) as CFData,
        ] as! [String: Any] as CFDictionary)

        guard status == errSecSuccess else {
            logger.error("Error adding access token to keychain for \(connectionID) & \(service): \(SecCopyErrorMessageString(status, nil))")
            throw PersistenceError.keychainInsertFailed
        }
    }
    func storeToken(_ token: String, for connectionID: String, service: CFString) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kCFBooleanFalse as Any,

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
    func removeToken(for connectionID: String, service: CFString) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,

            kSecAttrService: service,
            kSecAttrAccount: connectionID as CFString,
        ] as! [String: Any] as CFDictionary

        let status = SecItemDelete(query)

        guard status == errSecSuccess else {
            logger.error("Error removing access token to keychain for \(connectionID, privacy: .public) & \(service, privacy: .public): \(SecCopyErrorMessageString(status, nil), privacy: .public) (\(status, privacy: .public))")
            throw PersistenceError.keychainInsertFailed
        }
    }

    func updateConnections(_ connections: [Connection]) {
        connectionIDs = connections.map(\.id)
        friendlyConnections = connections.map { FriendlyConnection(from: $0) }
    }
}
