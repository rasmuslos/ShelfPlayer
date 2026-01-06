//
//  ContextProvider.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 21.03.25.
//

import Foundation
import OSLog
import Intents
import ShelfPlayback

public struct ContextProvider {
    static let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "ContextProvider")
    
    public static func updateUserContext() async {
        let totalCount = 42
//        let totalCount = await withTaskGroup {
//            for library in libraries {
//                $0.addTask {
//                    switch library.type {
//                    case .audiobooks:
//                        try? await ABSClient[library.connectionID].audiobooks(from: library.id, filter: .all, sortOrder: .added, ascending: false, limit: 1, page: 0).1
//                    case .podcasts:
//                        try? await ABSClient[library.connectionID].podcasts(from: library.id, sortOrder: .addedAt, ascending: false, limit: 1, page: 0).1
//                    }
//                }
//            }
//            
//            return await $0.reduce(0) {
//                $0 + ($1 ?? 0)
//            }
//        }
        
        let context = INMediaUserContext()
        context.numberOfLibraryItems = totalCount
        context.subscriptionStatus = .subscribed
        context.becomeCurrent()
        
        logger.info("Updated user context with \(totalCount) items")
    }
}
