//
//  MigrationManager.swift
//  ShelfPlayerMigration
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import OSLog

public actor MigrationManager {
    public enum State: Sendable {
        case notNeeded
        case available
        case inProgress(Double)
        case completed
        case failed(Error)
    }

    public static let shared = MigrationManager()

    public private(set) var state: State = .notNeeded

    private let logger = Logger(subsystem: "io.rfk.shelfPlayerMigration", category: "MigrationManager")

    private init() {}

    // MARK: - Detection

    public func detectOldInstallation() -> Bool {
        let groupContainer = Self.oldGroupContainer

        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupContainer) else {
            logger.info("Old group container not accessible")
            return false
        }

        let defaults = UserDefaults(suiteName: groupContainer)
        let hasDefaults = defaults?.dictionaryRepresentation().keys.count ?? 0 > 1

        let storeURL = containerURL
            .appending(path: "Library")
            .appending(path: "Application Support")
            .appending(path: "ShelfPlayerUpdated.store")

        let hasStore = FileManager.default.fileExists(atPath: storeURL.path(percentEncoded: false))

        let result = hasDefaults || hasStore

        if result {
            logger.info("Old installation detected (defaults: \(hasDefaults, privacy: .public), store: \(hasStore, privacy: .public))")
        }

        return result
    }

    public func wasMigrationCompleted() -> Bool {
        UserDefaults.standard.bool(forKey: "shelfPlayerMigrationCompleted")
    }

    // MARK: - Migration

    public func performMigration() async throws {
        guard !wasMigrationCompleted() else {
            logger.info("Migration already completed previously; skipping")
            state = .completed
            return
        }

        guard detectOldInstallation() else {
            logger.info("No old installation detected; migration not needed")
            state = .notNeeded
            return
        }

        logger.info("Starting migration: orchestrating keychain, defaults, and SwiftData migrators")
        state = .inProgress(0)

        do {
            state = .inProgress(0.1)
            logger.info("Running KeychainMigrator...")
            try KeychainMigrator.migrate()
            logger.info("KeychainMigrator complete")

            state = .inProgress(0.3)
            logger.info("Running DefaultsMigrator...")
            DefaultsMigrator.migrate()
            logger.info("DefaultsMigrator complete")

            state = .inProgress(0.5)
            logger.info("Running SwiftDataMigrator...")
            try await SwiftDataMigrator.migrate { progress in
                Task { @MainActor in
                    // Map SwiftData progress from 0.5 to 0.95
                    let mapped = 0.5 + progress * 0.45
                    await self.updateProgress(mapped)
                }
            }
            logger.info("SwiftDataMigrator complete")

            state = .inProgress(1.0)

            UserDefaults.standard.set(true, forKey: "shelfPlayerMigrationCompleted")
            UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: "shelfPlayerMigrationDate")

            state = .completed
            logger.info("Migration complete")
        } catch {
            state = .failed(error)
            logger.error("Migration failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func updateProgress(_ value: Double) {
        state = .inProgress(value)
    }

    // MARK: - Constants

    static var oldGroupContainer: String {
        #if DEBUG
        "group.io.rfk.shelfPlayer.development"
        #else
        "group.io.rfk.shelfplayer"
        #endif
    }
}
