//
//  ListenNowCache.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.05.25.
//

import Foundation
import OSLog
import Defaults
import RFNotifications
import SPFoundation
import SPNetwork

public actor ListenNowCache: Sendable {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListenNowCache")
    private var items = [PlayableItem]()
    
    private init() {
        RFNotification[.progressEntityUpdated].subscribe { [weak self] _ in
            Task {
                await self?.update()
            }
        }
        
        Task {
            for await _ in Defaults.updates([.downloadListenNowItems], initial: false) {
                await updateDownloads(items: items)
            }
        }
    }
    
    private func update() async {
        do {
            let entities = try await PersistenceManager.shared.progress.activeProgressEntities.sorted { $0.lastUpdate > $1.lastUpdate }
            let items = await withTaskGroup {
                for entity in entities {
                    $0.addTask {
                        try? await ABSClient[entity.connectionID].playableItem(primaryID: entity.primaryID, groupingID: entity.groupingID).0
                    }
                }
                
                return await $0.reduce(into: [PlayableItem]()) {
                    if let item = $1 {
                        $0.append(item)
                    }
                }
            }
            
            updateDownloads(items: items)
            
            self.items = entities.compactMap { entity in
                items.first {
                    $0.id.primaryID == entity.primaryID
                    && $0.id.groupingID == entity.groupingID
                    && $0.id.connectionID == entity.connectionID
                }
            }
        } catch {
            logger.error("Failed to update cache: \(error)")
        }
    }
    private nonisolated func updateDownloads(items: [PlayableItem]) {
        Task {
            let current = Defaults[.downloadedListenNowItems]
            var added: [ItemIdentifier]
            var expired: [ItemIdentifier]
            
            if Defaults[.downloadListenNowItems] {
                added = items.filter { !current.contains($0.id) }.map(\.id)
                expired = current.filter { existingID in !items.contains(where: { existingID == $0.id }) }
            } else {
                added = []
                expired = current
            }
            
            await withTaskGroup {
                for itemID in expired {
                    $0.addTask {
                        do {
                            try await PersistenceManager.shared.download.remove(itemID)
                        } catch {
                            self.logger.error("Failed to remove item \(itemID, privacy: .public): \(error)")
                        }
                    }
                }
            }
            let failed = await withTaskGroup {
                for itemID in added {
                    $0.addTask { () -> ItemIdentifier? in
                        do {
                            try await PersistenceManager.shared.download.download(itemID)
                            return nil
                        } catch {
                            self.logger.error("Failed to download item \(itemID, privacy: .public): \(error)")
                            return itemID
                        }
                    }
                }
                
                return await $0.compactMap { $0 }.reduce(into: []) { $0.append($1) }
            }
            
            Defaults[.downloadedListenNowItems] = added.filter { !failed.contains($0) }
        }
    }
    
    public func preload() {
        invalidate()
    }
    public func invalidate() {
        Task {
            await update()
        }
    }
    
    var current: [PlayableItem] {
        get async {
            guard items.isEmpty else {
                return items
            }
            
            await update()
            return items
        }
    }
    
    public static let shared = ListenNowCache()
}

