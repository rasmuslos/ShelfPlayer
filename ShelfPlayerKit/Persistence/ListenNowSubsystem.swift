//
//  ListenNowSubsystem.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import Foundation
import SwiftData
import OSLog

typealias PersistedListenNowSuggestion = SchemaV2.PersistedListenNowSuggestion

extension PersistenceManager {
    public final actor ListenNowSubsystem: ModelActor, Sendable {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListenNowSubsystem")
        
        private var items = [PlayableItem]()
        
        private var currentProgressIDs = [String]()
        private var unavailableProgressIDs = [String]()
        
        private var isEmpty = false
        
        public let modelExecutor: any SwiftData.ModelExecutor
        public let modelContainer: SwiftData.ModelContainer
        
        init(modelContainer: SwiftData.ModelContainer) {
            let modelContext = ModelContext(modelContainer)
            
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
            
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
        
        public func groupingDidFinishPlaying(_ itemID: ItemIdentifier) async {
            guard let suggested = try? await ResolvedUpNextStrategy.nextGroupingItem(itemID) else {
                logger.warning("No suggestion for item \(itemID)")
                return
            }
            
            // 4 Days
            let suggestion = PersistedListenNowSuggestion(itemID: suggested, type: .groupingFinishedPlaying, validUntil: .now.addingTimeInterval(60 * 60 * 24 * 4))
            modelContext.insert(suggestion)
            
            do {
                try modelContext.save()
            } catch {
                logger.error("Failed to save suggestion: \(error)")
            }
            
            logger.info("Stored suggestion for item \(itemID): \(suggested)")
            
            if let item = try? await itemID.resolved as? PlayableItem {
                items.insert(item, at: 0)
            }
        }
    }
}

extension PersistenceManager.ListenNowSubsystem {
    private func update() async {
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
            let connectionGrouped = Dictionary(grouping: duplicates, by: \.connectionID)
            
            for (connectionID, itemIDs) in connectionGrouped {
                let primaryIDs = itemIDs.map(\.primaryID)
                let groupingIDs = itemIDs.map(\.primaryID)
                
                let combined = primaryIDs + groupingIDs
                
                for itemID in combined {
                    try modelContext.delete(model: PersistedListenNowSuggestion.self, where: #Predicate {
                        $0._itemID.contains(connectionID)
                        && $0._itemID.contains(itemID)
                    })
                }
            }
            
            items.removeAll { (_, progressID, item, related) in
                progressID == nil && related.contains { duplicates.contains($0) }
            }
        }
        
        try modelContext.save()
        
        return items.compactMap(\.2)
    }
    private func listenNowSuggestions() async throws -> [(Date, String?, ItemIdentifier.PrimaryID, ItemIdentifier.GroupingID?, ItemIdentifier.ConnectionID)] {
        try modelContext.fetch(FetchDescriptor<PersistedListenNowSuggestion>()).filter {
            guard $0.validUntil > .now else {
                modelContext.delete($0)
                return false
            }
            
            return true
        }.map { ($0.created.advanced(by: -60 * 60 * 24 * 2), nil, $0.itemID.primaryID, $0.itemID.groupingID, $0.itemID.connectionID) }
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
