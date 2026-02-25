//
//  ListenNowSubsystem.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import Foundation
import OSLog

extension PersistenceManager {
    public final actor ListenNowSubsystem: Sendable {
        fileprivate static let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListenNow")
        
        let lifetime: TimeInterval = 60 * 3
        
        private let cache = NSCache<NSString, NSArray>()
        private var updateTask = [ItemIdentifier.ItemType: Task<([Result], Date), Error>]()
        
        private var lastSingleCacheKey: String?
        private var updateSingleTask: Task<([PlayableItem], Date), Error>?
        
        init() {
            RFNotification[.progressEntityUpdated].subscribe { [weak self] _ in
                Task {
                    await self?.invalidate()
                }
            }
            RFNotification[.invalidateProgressEntities].subscribe { [weak self] _ in
                Task {
                    await self?.invalidate()
                }
            }
            RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
                Task {
                    await self?.invalidate()
                }
            }
        }
    }
}

public extension PersistenceManager.ListenNowSubsystem {
    var current: [PlayableItem] {
        get async throws {
            if let (items, timestamp) = try? await updateSingleTask?.value, timestamp.distance(to: .now) < lifetime {
                items
            } else {
                try await combineIntoSingle()
            }
        }
    }
    func current(itemType type: ItemIdentifier.ItemType) async throws -> [Item] {
        try await results(itemType: type).map(\.item)
    }
    
    func invalidate() {
        updateSingleTask = nil
        updateTask.removeAll()
        
        Task {
            let _ = try? await current
        }
    }
}

// MARK: Scheduler

private extension PersistenceManager.ListenNowSubsystem {
    func results(itemType type: ItemIdentifier.ItemType) async throws -> [Result] {
        if let (items, timestamp) = try? await updateTask[type]?.value, timestamp.distance(to: .now) < lifetime {
            return items
        } else {
            return try await update(type: type)
        }
    }
    func update(type: ItemIdentifier.ItemType) async throws -> [Result] {
        updateTask[type] = .init {
            (try await resolve(), .now)
        }
        
        return try await updateTask[type]!.value.0
    }
}

// MARK: Resolve

private extension PersistenceManager.ListenNowSubsystem {
    nonisolated func resolve() async throws -> [Result] {
        var resolvers = [any ListenNowResolver]()
        
        resolvers.append(PlayableItemProgressActiveResolver())
        
        let results = try await withThrowingTaskGroup(returning: [[Result]].self) {
            for resolver in resolvers {
                $0.addTask {
                    do {
                        return try await self.resolve(resolver)
                    } catch {
                        Self.logger.error("Failed to resolve listen now items for \(resolver.id): \(error)")
                        throw error
                    }
                }
            }

            return try await $0.reduce(into: []) {
                $0.append($1)
            }
        }
        
        return combine(results)
    }
    
    func combineIntoSingle() async throws -> [PlayableItem] {
        updateSingleTask = .init {
            let (audiobooks, series, episodes, podcasts) = try await (
                results(itemType: .audiobook),
                results(itemType: .series),
                results(itemType: .episode),
                results(itemType: .podcast),
            )
         
            let items = combine([
                audiobooks,
                episodes,
            ]).compactMap {
                $0.item as? PlayableItem
            }
            
            let cacheKey = items.reduce("") { $0 + $1.id.description }
            
            if lastSingleCacheKey != cacheKey {
                await RFNotification[.listenNowItemsChanged].send()
            }
            lastSingleCacheKey = cacheKey
            
            return (items, .now)
        }
        
        return try await updateSingleTask!.value.0
    }
    
    nonisolated func combine(_ input: [[Result]]) -> [Result] {
        let keyed = input.reduce([]) {
            $0 + $1.map { ($0.item.id, $0) }
        }
        let result = Dictionary(keyed) {
            $0.timestamp > $1.timestamp ? $0 : $1
        }
        
        let merged = result.map { $1 }
        
        return merged.sorted {
            $0.timestamp > $1.timestamp
        }
    }
    
    protocol ListenNowResolver: Sendable, Hashable {
        var id: String { get }
        
        func resolve() async throws -> [Result]
        func cacheIdentifier() async throws -> NSString
    }
    struct Result: Sendable {
        let item: Item
        let timestamp: Date
        let relevance: Percentage
        
        init(item: Item, timestamp: Date, relevance: Percentage) {
            self.item = item
            self.timestamp = timestamp
            self.relevance = relevance
        }
    }
}

// MARK: Cache

private extension PersistenceManager.ListenNowSubsystem {
    func resolve(_ resolver: any ListenNowResolver) async throws -> [Result] {
        let cacheKey = try await resolver.cacheIdentifier()
        
        if let cached = cache.object(forKey: cacheKey) as? [Result] {
            return cached
        }
        
        let result = try await resolver.resolve()
        
        cache.setObject(result as NSArray, forKey: cacheKey)
        return result
    }
}

// MARK: Resolvers

private struct PlayableItemProgressActiveResolver: PersistenceManager.ListenNowSubsystem.ListenNowResolver {
    var id: String {
        "playable-item-progress-active"
    }
    func cacheIdentifier() async throws -> NSString {
        let entities = try await PersistenceManager.shared.progress.activeProgressEntities.sorted { $0.lastUpdate < $1.lastUpdate }
        let isOffline = await OfflineMode.shared.isEnabled
        
        return NSString(string: "\(isOffline)_\(entities.reduce("") { $0 + $1.connectionID + $1.primaryID + ($1.groupingID ?? ".") })")
    }
    
    func resolve() async throws -> [PersistenceManager.ListenNowSubsystem.Result] {
        let entities = try await PersistenceManager.shared.progress.activeProgressEntities

        var resolved = [PersistenceManager.ListenNowSubsystem.Result]()
        
        for entity in entities {
            do {
                guard let item = try await Self.resolve(primaryID: entity.primaryID, groupingID: entity.groupingID, connectionID: entity.connectionID) else {
                    continue
                }
                
                resolved.append(.init(item: item, timestamp: entity.lastUpdate, relevance: 70))
            } catch {
                throw error
            }
        }
        
        return resolved
    }
    static func resolve(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) async throws -> Item? {
        do {
            let item = try await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
            
            if await !OfflineMode.shared.isAvailable(connectionID) {
                guard await PersistenceManager.shared.download.status(of: item.id) == .completed else {
                    return nil
                }
            }
            
            return item
        } catch APIClientError.offline {
            PersistenceManager.ListenNowSubsystem.logger.warning("Failed to resolve listen now entity because offline: \(primaryID)")
            return nil
        } catch {
            throw error
        }
    }
}
