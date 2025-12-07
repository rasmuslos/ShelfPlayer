//
//  Cache.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import ShelfPlayerKit

final actor Cache: Sendable {
    typealias ImageCache = [ItemIdentifier: Data]
    
    var covers = ImageCache()
    var tinyCovers = ImageCache()
    
    var entities = [ItemIdentifier: ItemEntity]()
    
    private func cachedCover(for itemID: ItemIdentifier, tiny: Bool) -> Data? {
        if tiny {
            tinyCovers[itemID]
        } else {
            covers[itemID]
        }
    }
    
    func cover(for itemID: ItemIdentifier, tiny: Bool = false) async -> Data? {
        if let cached = cachedCover(for: itemID, tiny: tiny) {
            cached
        } else {
            await covers(for: [itemID], tiny: tiny).values.first
        }
    }
    func covers(for itemIDs: [ItemIdentifier], tiny: Bool) async -> [ItemIdentifier: Data] {
        try? await PersistenceManager.shared.authorization.waitForConnections()
        
        var result = [ItemIdentifier: Data]()
        var missingItemIDs: [ItemIdentifier] = []
        
        for itemID in itemIDs {
            if let cached = cachedCover(for: itemID, tiny: tiny) {
                result[itemID] = cached
            } else {
                missingItemIDs.append(itemID)
            }
        }
        
        let fetched = await withTaskGroup {
            for itemID in missingItemIDs {
                $0.addTask {
                    (itemID, await itemID.data(size: tiny ? .tiny : .small))
                }
            }
            
            return await $0.reduce(into: [:]) { $0[$1.0] = $1.1 }
        }
        
        if tiny {
            tinyCovers.merge(fetched) { $1 }
        } else {
            covers.merge(fetched) { $1 }
        }
        
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
