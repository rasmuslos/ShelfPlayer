//
//  KeychainMigrator.swift
//  ShelfPlayerMigration
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import Security
import OSLog

enum KeychainMigrator {
    private static let logger = Logger(subsystem: "io.rfk.shelfPlayerMigration", category: "KeychainMigrator")

    static func migrate() throws {
        // No keychain migration needed — the app uses the same bundle ID,
        // keychain access groups, and service names as the old ShelfPlayer app.
        logger.info("Keychain migration skipped (same identifiers)")
    }

}

// MARK: - Errors

enum MigrationError: Error, LocalizedError {
    case swiftDataContainerNotFound
    case swiftDataReadFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .swiftDataContainerNotFound:
            "Old SwiftData container not found"
        case .swiftDataReadFailed(let underlying):
            "Failed to read old SwiftData container: \(underlying.localizedDescription)"
        }
    }
}
