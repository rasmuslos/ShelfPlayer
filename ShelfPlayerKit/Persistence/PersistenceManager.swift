//
//  PersistenceManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import SwiftData
import Intents
import AppIntents
import RFNotifications

public final class PersistenceManager: Sendable {
    public let modelContainer: ModelContainer
    
    public let keyValue: KeyValueSubsystem
    public let authorization: AuthorizationSubsystem
    
    
    public let progress: ProgressSubsystem
    public let session: SessionSubsystem
    
    public let download: DownloadSubsystem
    public let convenienceDownload: ConvenienceDownloadSubsystem
    
    public let item: ItemSubsystem
    public let bookmark: BookmarkSubsystem
    
    private init() {
        let schema = Schema(versionedSchema: SchemaV2.self)
        
        let modelConfiguration = ModelConfiguration("ShelfPlayerUpdated",
                           schema: schema,
                           isStoredInMemoryOnly: false,
                           allowsSave: true,
                           groupContainer: ShelfPlayerKit.enableCentralized ? .identifier(ShelfPlayerKit.groupContainer) : .none,
                           cloudKitDatabase: .none)
        
        #if DEBUG
        // try! FileManager.default.removeItem(at: modelConfiguration.url)
        #endif
        
        modelContainer = try! ModelContainer(for: schema, migrationPlan: nil, configurations: [
            modelConfiguration,
        ])
        
        keyValue = .init(modelContainer: modelContainer)
        authorization = .init(modelContainer: modelContainer)
        
        progress = .init(modelContainer: modelContainer)
        session = .init(modelContainer: modelContainer)
        
        download = .init(modelContainer: modelContainer)
        convenienceDownload = .init()
        
        item = .init()
        bookmark = .init(modelContainer: modelContainer)
    }
    
    public func remove(itemID: ItemIdentifier) async {
        await keyValue.remove(itemID: itemID)
        await progress.remove(itemID: itemID)
        await session.remove(itemID: itemID)
        
        try? await download.remove(itemID)
        await convenienceDownload.remove(itemID: itemID, configurationID: nil)
        
        await bookmark.remove(itemID: itemID)
        
        let _ = try? await IntentDonationManager.shared.deleteDonations(matching: .entityIdentifier(EntityIdentifier(for: ItemEntity.self, identifier: itemID)))
        let _ = try? await IntentDonationManager.shared.deleteDonations(matching: .entityIdentifier(EntityIdentifier(for: AudiobookEntity.self, identifier: itemID)))
        
        try? await INInteraction.delete(with: itemID.description)
        
        NSUserActivity.deleteSavedUserActivities(withPersistentIdentifiers: [itemID.description]) {}
    }
    public func remove(connectionID: ItemIdentifier.ConnectionID) async {
        await keyValue.remove(connectionID: connectionID)
        await authorization.remove(connectionID: connectionID)
        await progress.remove(connectionID: connectionID)
        await session.remove(connectionID: connectionID)
        await download.remove(connectionID: connectionID)
        await bookmark.remove(connectionID: connectionID)
        
        await RFNotification[.removeConnection].send(payload: connectionID)
    }
    
    public func refreshItem(itemID: ItemIdentifier) async throws {
        try await keyValue.purgeCached(itemID: itemID)
    }
    public func invalidateCache() async throws {
        try await keyValue.purgeCached()
    }
}

enum PersistenceError: Error {
    case missing
    case existing
    
    case busy
    case blocked
    
    case unsupportedItemType
    case unsupportedDownloadCodec
    
    case serverNotFound
    case keychainInsertFailed
    case keychainRetrieveFailed
}

// MARK: Singleton

public extension PersistenceManager {
    static let shared = PersistenceManager()
}
