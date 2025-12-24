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
    
    var accessToken: String?
    var configuration: (URL, [HTTPHeader])
    
    init(connectionID: ItemIdentifier.ConnectionID) async throws {
        self.connectionID = connectionID
        
        accessToken = try? await PersistenceManager.shared.authorization.accessToken(for: connectionID)
        configuration = try await PersistenceManager.shared.authorization.configuration(for: connectionID)
    }
    
    func refreshAccessToken() async throws {
        do {
            accessToken = try await PersistenceManager.shared.authorization.refreshAccessToken(for: connectionID)
        } catch {
            await RFNotification[.connectionUnauthorized].send(payload: connectionID)
            throw error
        }
    }
}
