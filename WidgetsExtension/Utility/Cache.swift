//
//  Cache.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import ShelfPlayerKit

final actor Cache: Sendable {
    var covers = [ItemIdentifier: Data]()
    var entities = [ItemIdentifier: ItemEntity]()
    
    func cover(for itemID: ItemIdentifier) async -> Data? {
        if let cachedData = covers[itemID] {
            cachedData
        } else {
            await covers(for: [itemID]).values.first
        }
    }
    func covers(for itemIDs: [ItemIdentifier]) async -> [ItemIdentifier: Data] {
        if await PersistenceManager.shared.authorization.connections.isEmpty {
            try? await PersistenceManager.shared.authorization.fetchConnections()
        }
        
        var result = [ItemIdentifier: Data]()
        var missingItemIDs: [ItemIdentifier] = []
        
        for itemID in itemIDs {
            if let cachedData = covers[itemID] {
                result[itemID] = cachedData
            } else {
                missingItemIDs.append(itemID)
            }
        }
        
        let fetched = await withTaskGroup {
            for itemID in missingItemIDs {
                $0.addTask {
                    (itemID, await itemID.data(size: .regular))
                }
            }
            
            return await $0.reduce(into: [:]) { $0[$1.0] = $1.1 }
        }
        
        covers.merge(fetched) { $1 }
        result.merge(fetched) { $1 }
        
        return result
    }
    
    func entity(for itemID: ItemIdentifier) async -> ItemEntity? {
        if let cachedIntent = entities[itemID] {
            cachedIntent
        } else {
            await entities(for: [itemID]).values.first
        }
    }
    func entities(for itemIDs: [ItemIdentifier]) async -> [ItemIdentifier: ItemEntity] {
        var result = [ItemIdentifier: ItemEntity]()
        var missingItemIDs: [ItemIdentifier] = []
        
        for itemID in itemIDs {
            if let cachedIntent = entities[itemID] {
                result[itemID] = cachedIntent
            } else {
                missingItemIDs.append(itemID)
            }
        }
        
        let fetched = await withTaskGroup {
            for itemID in missingItemIDs {
                $0.addTask {
                    (itemID, try? await ItemEntity(item: itemID.resolved))
                }
            }
            
            return await $0.reduce(into: [:]) { $0[$1.0] = $1.1 }
        }
        
        entities.merge(fetched) { $1 }
        result.merge(fetched) { $1 }
        
        return result
    }
    
    static let shared = Cache()
}
