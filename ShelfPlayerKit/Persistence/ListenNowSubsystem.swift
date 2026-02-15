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
            items
        } else {
            try await update(type: type)
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
            
            if await OfflineMode.shared.isEnabled {
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

//
//import Foundation
//import SwiftData
//import OSLog
//
//    public final actor ListenNowSubsystem: Sendable {
//
//        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListenNowSubsystem")
//
//        private var items = [PlayableItem]()
//
//        private var currentProgressIDs = [String]()
//        private var unavailableProgressIDs = [String]()
//
//        private var isEmpty = false
//
//        private var lastUpdateStarted: Date?
//
//        init() {
//            RFNotification[.progressEntityUpdated].subscribe { [weak self] _ in
//                Task {
//                    await self?.update()
//                }
//            }
//            RFNotification[.invalidateProgressEntities].subscribe { [weak self] _ in
//                Task {
//                    await self?.update()
//                }
//            }
//
//            RFNotification[.playbackItemChanged].subscribe { [weak self] _ in
//                Task {
//                    await self?.update()
//                }
//            }
//            RFNotification[.playbackStopped].subscribe { [weak self] _ in
//                Task {
//                    await self?.update()
//                }
//            }
//        }
//    }
//}
//
//extension PersistenceManager.ListenNowSubsystem {
//    private func update() async {
//        if await OfflineMode.shared.isEnabled {
//            return
//        }
////        if let lastUpdateStarted, lastUpdateStarted.distance(to: .now) < -7 {
////            return
////        }
//
//        lastUpdateStarted = .now
//
//        do {
//            let items = try await listenNowItems()
//
//            guard self.items != items else {
//                return
//            }
//
//            self.items = items
//            await RFNotification[.listenNowItemsChanged].send()
//        } catch {
//            logger.error("Failed to update cache: \(error)")
//        }
//    }
//    public func listenNowItems() async throws -> [PlayableItem] {
//        let identifiers = try await withThrowingTaskGroup(of: [(Date, String?, String, String?, String)].self) {
//            $0.addTask { try await PersistenceManager.shared.progress.activeProgressEntities.map { ($0.lastUpdate, $0.id, $0.primaryID, $0.groupingID, $0.connectionID) } }
//            $0.addTask { try await PersistenceManager.shared.listenNow.listenNowSuggestions() }
//
//            return try await $0.reduce(into: []) {
//                $0.append(contentsOf: $1)
//            }
//        }
//
//        var items = await withTaskGroup(of: (Date, String?, PlayableItem?, [ItemIdentifier]).self) {
//            for (date, progressID, primaryID, groupingID, connectionID) in identifiers {
//                $0.addTask {
//                    do {
//                        let item = try await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
//
//                        let relatedItemIDs: [ItemIdentifier]
//
//                        switch item {
//                            case let audiobook as Audiobook:
//                                relatedItemIDs = [audiobook.id] + audiobook.series.compactMap(\.id)
//                            case let episode as Episode:
//                                relatedItemIDs = [episode.id, episode.podcastID]
//                            default:
//                                relatedItemIDs = [item.id]
//                        }
//
//                        return (date, progressID, item, relatedItemIDs)
//                    } catch {
//                        return (date, progressID, nil, [])
//                    }
//                }
//            }
//
//            return await $0.reduce(into: []) { $0.append($1) }
//        }.sorted { $0.0 > $1.0 }
//
//        currentProgressIDs = items.compactMap { $0.2 != nil ? $0.1 : nil }
//        unavailableProgressIDs = items.compactMap { $0.2 == nil ? $0.1 : nil }
//
//        let progressRelatedItemIDs: Set<ItemIdentifier> = items.reduce(into: []) {
//            guard $1.1 != nil else {
//                return
//            }
//
//            for itemID in $1.3 {
//                $0.insert(itemID)
//            }
//        }
//        let suggestionRelatedItemIDs: Set<ItemIdentifier> = items.reduce(into: []) {
//            guard $1.1 == nil else {
//                return
//            }
//
//            for itemID in $1.3 {
//                $0.insert(itemID)
//            }
//        }
//
//        let duplicates = progressRelatedItemIDs.intersection(suggestionRelatedItemIDs)
//
//        if !duplicates.isEmpty {
//            items.removeAll { (_, progressID, item, related) in
//                progressID == nil && related.contains { duplicates.contains($0) }
//            }
//        }
//
//        return items.compactMap(\.2)
//    }
//    private func listenNowSuggestions() async throws -> [(Date, String?, ItemIdentifier.PrimaryID, ItemIdentifier.GroupingID?, ItemIdentifier.ConnectionID)] {
//        let recentlyFinished = try await PersistenceManager.shared.progress.recentlyFinishedEntities
//
//        let groupingIDs: [(ItemIdentifier, Date)] = await withTaskGroup {
//            for entity in recentlyFinished {
//                $0.addTask { () -> (ItemIdentifier, Date)? in
//                    let id: ItemIdentifier
//
//                    if let groupingID = entity.groupingID {
//                        guard let podcast = try? await ResolveCache.shared.resolve(primaryID: groupingID, connectionID: entity.connectionID).0, await PersistenceManager.shared.item.allowSuggestions(for: podcast.id) != false else {
//                            return nil
//                        }
//
//                        id = podcast.id
//                    } else {
//                        guard let audiobook = try? await ResolveCache.shared.resolve(primaryID: entity.primaryID, groupingID: nil, connectionID: entity.connectionID) as? Audiobook else {
//                            return nil
//                        }
//
//                        var resultID: ItemIdentifier? = nil
//
//                        for series in audiobook.series {
//                            guard let seriesID = series.id, await PersistenceManager.shared.item.allowSuggestions(for: seriesID) != false, (try? await ResolvedUpNextStrategy.nextGroupingItem(seriesID)) != nil else {
//                                continue
//                            }
//
//                            resultID = seriesID
//                        }
//
//                        guard let resultID else {
//                            return nil
//                        }
//
//                        id = resultID
//                    }
//
//                    return (id, entity.finishedAt!)
//                }
//            }
//
//            return await $0.reduce(into: []) {
//                guard let element = $1 else {
//                    return
//                }
//
//                $0.append(element)
//            }
//        }
//
//        let grouped = Dictionary(groupingIDs) {
//            max($0, $1)
//        }
//
//        return await withTaskGroup {
//            for (itemID, date) in grouped {
//                $0.addTask { () -> (ItemIdentifier, Date)? in
//                    guard let nextID = try? await ResolvedUpNextStrategy.nextGroupingItem(itemID) else {
//                        return nil
//                    }
//
//                    return (nextID, date.advanced(by: -60 * 60 * 24 * 4))
//                }
//            }
//
//            return await $0.reduce(into: []) {
//                guard let (itemID, date) = $1 else {
//                    return
//                }
//
//                $0.append((date, nil as String?, itemID.primaryID, itemID.groupingID, itemID.connectionID))
//            }
//        }
//    }
//
//    public func preload() {
//        invalidate()
//    }
//    public func invalidate() {
//        isEmpty = false
//
//        currentProgressIDs.removeAll()
//        unavailableProgressIDs.removeAll()
//
//        Task {
//            await update()
//        }
//    }
//
//    var current: [PlayableItem] {
//        get async {
//            guard !items.isEmpty || isEmpty else {
//                await update()
//                return items
//            }
//
//            return items
//        }
//    }
//}
