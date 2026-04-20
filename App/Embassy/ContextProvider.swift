//
//  ContextProvider.swift
//  ShelfPlayer
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

        let context = INMediaUserContext()
        context.numberOfLibraryItems = totalCount
        context.subscriptionStatus = .subscribed
        context.becomeCurrent()

        logger.info("Updated user context with \(totalCount) items")
    }
}
