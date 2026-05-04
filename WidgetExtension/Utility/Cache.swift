//
//  Cache.swift
//  WidgetExtension
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import OSLog
import ShelfPlayerKit

final actor Cache: Sendable {
    typealias ImageCache = [ItemIdentifier: Data]

    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "WidgetCache")

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
        var result = [ItemIdentifier: Data]()
        var missingItemIDs: [ItemIdentifier] = []

        for itemID in itemIDs {
            if let cached = cachedCover(for: itemID, tiny: tiny) {
                result[itemID] = cached
            } else {
                missingItemIDs.append(itemID)
            }
        }

        let fetched: [ItemIdentifier: Data] = await withTaskGroup(of: (ItemIdentifier, Data?).self) { group in
            for itemID in missingItemIDs {
                group.addTask { [logger] in
                    let data = await itemID.data(size: tiny ? .tiny : .small)
                    if data == nil {
                        logger.error("Failed to fetch cover for item \(itemID, privacy: .public) (tiny=\(tiny, privacy: .public))")
                    }
                    return (itemID, data)
                }
            }

            var collected: [ItemIdentifier: Data] = [:]
            for await (itemID, data) in group {
                if let data {
                    collected[itemID] = data
                }
            }
            return collected
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

        let fetched: [ItemIdentifier: ItemEntity] = await withTaskGroup(of: (ItemIdentifier, ItemEntity?).self) { group in
            for itemID in missingItemIDs {
                group.addTask { [logger] in
                    do {
                        let entity = try await ItemEntity(item: itemID.resolved)
                        return (itemID, Optional(entity))
                    } catch {
                        logger.error("Failed to resolve entity for item \(itemID, privacy: .public): \(error.localizedDescription, privacy: .public)")
                        return (itemID, nil)
                    }
                }
            }

            var collected: [ItemIdentifier: ItemEntity] = [:]
            for await (itemID, entity) in group {
                if let entity {
                    collected[itemID] = entity
                }
            }
            return collected
        }

        entities.merge(fetched) { $1 }
        result.merge(fetched) { $1 }

        return result
    }

    static let shared = Cache()
}
