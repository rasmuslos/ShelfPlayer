//
//  ListenNowSubsystem.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import Foundation
import SwiftData
import OSLog

extension PersistenceManager {
    public final actor ListenNowSubsystem: Sendable {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListenNowSubsystem")
        
        private var items = [PlayableItem]()
        
        private var currentProgressIDs = [String]()
        private var unavailableProgressIDs = [String]()
        
        private var isEmpty = false
        
        private var lastUpdateStarted: Date?
        
        init() {
            RFNotification[.progressEntityUpdated].subscribe { [weak self] _ in
                Task {
                    await self?.update()
                }
            }
            RFNotification[.invalidateProgressEntities].subscribe { [weak self] _ in
                Task {
                    await self?.update()
                }
            }
            
            RFNotification[.playbackItemChanged].subscribe { [weak self] _ in
                Task {
                    await self?.update()
                }
            }
            RFNotification[.playbackStopped].subscribe { [weak self] _ in
                Task {
                    await self?.update()
                }
            }
        }
    }
}

extension PersistenceManager.ListenNowSubsystem {
    private func update() async {
        if let lastUpdateStarted, lastUpdateStarted.distance(to: .now) < -7 {
            
        }
        
        lastUpdateStarted = .now
        
        do {
            let items = try await listenNowItems()
            
            guard self.items != items else {
                return
            }
            
            self.items = items
            await RFNotification[.listenNowItemsChanged].send()
        } catch {
            logger.error("Failed to update cache: \(error)")
        }
    }
    public func listenNowItems() async throws -> [PlayableItem] {
        let identifiers = try await withThrowingTaskGroup(of: [(Date, String?, String, String?, String)].self) {
            $0.addTask { try await PersistenceManager.shared.progress.activeProgressEntities.map { ($0.lastUpdate, $0.id, $0.primaryID, $0.groupingID, $0.connectionID) } }
            $0.addTask { try await PersistenceManager.shared.listenNow.listenNowSuggestions() }
            
            return try await $0.reduce(into: []) {
                $0.append(contentsOf: $1)
            }
        }
        
        var items = await withTaskGroup(of: (Date, String?, PlayableItem?, [ItemIdentifier]).self) {
            for (date, progressID, primaryID, groupingID, connectionID) in identifiers {
                $0.addTask {
                    do {
                        let item = try await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                        
                        let relatedItemIDs: [ItemIdentifier]
                        
                        switch item {
                            case let audiobook as Audiobook:
                                relatedItemIDs = [audiobook.id] + audiobook.series.compactMap(\.id)
                            case let episode as Episode:
                                relatedItemIDs = [episode.id, episode.podcastID]
                            default:
                                relatedItemIDs = [item.id]
                        }
                        
                        return (date, progressID, item, relatedItemIDs)
                    } catch {
                        return (date, progressID, nil, [])
                    }
                }
            }
            
            return await $0.reduce(into: []) { $0.append($1) }
        }.sorted { $0.0 > $1.0 }
        
        currentProgressIDs = items.compactMap { $0.2 != nil ? $0.1 : nil }
        unavailableProgressIDs = items.compactMap { $0.2 == nil ? $0.1 : nil }
        
        let progressRelatedItemIDs: Set<ItemIdentifier> = items.reduce(into: []) {
            guard $1.1 != nil else {
                return
            }
            
            for itemID in $1.3 {
                $0.insert(itemID)
            }
        }
        let suggestionRelatedItemIDs: Set<ItemIdentifier> = items.reduce(into: []) {
            guard $1.1 == nil else {
                return
            }
            
            for itemID in $1.3 {
                $0.insert(itemID)
            }
        }
        
        let duplicates = progressRelatedItemIDs.intersection(suggestionRelatedItemIDs)
        
        if !duplicates.isEmpty {
            items.removeAll { (_, progressID, item, related) in
                progressID == nil && related.contains { duplicates.contains($0) }
            }
        }
        
        return items.compactMap(\.2)
    }
    private func listenNowSuggestions() async throws -> [(Date, String?, ItemIdentifier.PrimaryID, ItemIdentifier.GroupingID?, ItemIdentifier.ConnectionID)] {
        let recentlyFinished = try await PersistenceManager.shared.progress.recentlyFinishedEntities
        
        let groupingIDs: [(ItemIdentifier, Date)] = await withTaskGroup {
            for entity in recentlyFinished {
                $0.addTask { () -> (ItemIdentifier, Date)? in
                    let id: ItemIdentifier
                    
                    if let groupingID = entity.groupingID {
                        guard let podcast = try? await ResolveCache.shared.resolve(primaryID: groupingID, connectionID: entity.connectionID).0, await PersistenceManager.shared.item.allowSuggestions(for: podcast.id) != false else {
                            return nil
                        }
                        
                        id = podcast.id
                    } else {
                        guard let audiobook = try? await ResolveCache.shared.resolve(primaryID: entity.primaryID, groupingID: nil, connectionID: entity.connectionID) as? Audiobook else {
                            return nil
                        }
                        
                        var resultID: ItemIdentifier? = nil
                        
                        for series in audiobook.series {
                            guard let seriesID = series.id, await PersistenceManager.shared.item.allowSuggestions(for: seriesID) != false, (try? await ResolvedUpNextStrategy.nextGroupingItem(seriesID)) != nil else {
                                continue
                            }
                            
                            resultID = seriesID
                        }
                        
                        guard let resultID else {
                            return nil
                        }
                        
                        id = resultID
                    }
                    
                    return (id, entity.finishedAt!)
                }
            }
            
            return await $0.reduce(into: []) {
                guard let element = $1 else {
                    return
                }
                 
                $0.append(element)
            }
        }
        
        let grouped = Dictionary(groupingIDs) {
            max($0, $1)
        }
        
        return await withTaskGroup {
            for (itemID, date) in grouped {
                $0.addTask { () -> (ItemIdentifier, Date)? in
                    guard let nextID = try? await ResolvedUpNextStrategy.nextGroupingItem(itemID) else {
                        return nil
                    }
                    
                    return (nextID, date.advanced(by: -60 * 60 * 24 * 4))
                }
            }
            
            return await $0.reduce(into: []) {
                guard let (itemID, date) = $1 else {
                    return
                }
                
                $0.append((date, nil as String?, itemID.primaryID, itemID.groupingID, itemID.connectionID))
            }
        }
    }
    
    public func preload() {
        invalidate()
    }
    public func invalidate() {
        isEmpty = false
        
        currentProgressIDs.removeAll()
        unavailableProgressIDs.removeAll()
        
        Task {
            await update()
        }
    }
    
    var current: [PlayableItem] {
        get async {
            guard !items.isEmpty || isEmpty else {
                await update()
                return items
            }
            
            return items
        }
    }
}
