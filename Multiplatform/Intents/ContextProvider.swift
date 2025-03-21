//
//  ContextProvider.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 21.03.25.
//

import Foundation
import OSLog
import Intents
import ShelfPlayerKit

struct ContextProvider {
    static let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "ContextProvider")
    
    static func updateUserContext() async {
        var totalCount = 0
        
        for connectionID in await PersistenceManager.shared.authorization.connections.keys {
            do {
                let libraries = try await ABSClient[connectionID].libraries()
                
                for library in libraries {
                    switch library.type {
                    case .audiobooks:
                        totalCount += try await ABSClient[connectionID].audiobooks(from: library.id, filter: .all, sortOrder: .added, ascending: false, limit: 0, page: 0).1
                    case .podcasts:
                        totalCount += try await ABSClient[connectionID].podcasts(from: library.id, sortOrder: .addedAt, ascending: false, limit: 0, page: 0).1
                    }
                }
            } catch {
                logger.error("Failed to update user context for connection \(connectionID): \(error)")
            }
        }
        
        let context = INMediaUserContext()
        context.numberOfLibraryItems = totalCount
        context.subscriptionStatus = .subscribed
        context.becomeCurrent()
        
        logger.info("Updated user context with \(totalCount) items")
    }
}
