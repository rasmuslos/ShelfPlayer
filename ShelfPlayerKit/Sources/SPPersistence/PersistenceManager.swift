//
//  PersistenceManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import SwiftData
import SPFoundation

public final class PersistenceManager: Sendable {
    public let keyValue: KeyValueSubsystem
    public let authorization: AuthorizationSubsystem
    
    private init() {
        let schema = Schema(versionedSchema: SchemaV2.self)
        
        let modelConfiguration = ModelConfiguration("ShelfPlayer",
                           schema: schema,
                           isStoredInMemoryOnly: false,
                           allowsSave: true,
                           groupContainer: ShelfPlayerKit.enableCentralized ? .identifier(ShelfPlayerKit.groupContainer) : .none,
                           cloudKitDatabase: .none)
        
        let container = try! ModelContainer(for: schema, migrationPlan: Migration.self, configurations: [
            modelConfiguration,
        ])
        
        keyValue = .init(modelContainer: container)
        authorization = .init(modelContainer: container)
    }
    
    enum PersistenceError: Error {
        case serverNotFound
        case keychainInsertFailed
        case keychainRetrieveFailed
    }
}

// MARK: Singleton

public extension PersistenceManager {
    static let shared = PersistenceManager()
}
