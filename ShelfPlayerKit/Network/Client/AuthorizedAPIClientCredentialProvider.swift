//
//  AuthorizedAPIClientCredentialProvider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 17.08.25.
//

import Foundation
import OSLog

final actor AuthorizedAPIClientCredentialProvider: APICredentialProvider {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "AuthorizedAPIClientCredentialProvider")
    
    let connectionID: ItemIdentifier.ConnectionID
    let isRefreshProvider: Bool
    
    var accessToken: String?
    var configuration: (URL, [HTTPHeader])
    
    init(connectionID: ItemIdentifier.ConnectionID, isRefreshProvider: Bool = false) async throws {
        self.connectionID = connectionID
        self.isRefreshProvider = isRefreshProvider
        
        accessToken = try? await PersistenceManager.shared.authorization.accessToken(for: connectionID)
        configuration = try await PersistenceManager.shared.authorization.configuration(for: connectionID)
    }
    
    func refreshAccessToken() async throws {
        guard !isRefreshProvider else {
            throw APIClientError.unauthorized
        }
        
        do {
            accessToken = try await PersistenceManager.shared.authorization.refreshAccessToken(for: connectionID)
        } catch {
            logger.error("Access token refresh failed for \(self.connectionID, privacy: .public). Dispatching connectionUnauthorized notification. Cause: \(error, privacy: .public)")
            await RFNotification[.connectionUnauthorized].send(payload: self.connectionID)
            logger.info("Dispatched connectionUnauthorized notification for \(self.connectionID, privacy: .public)")
            throw error
        }
    }
}
