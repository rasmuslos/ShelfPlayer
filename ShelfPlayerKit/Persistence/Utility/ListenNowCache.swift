//
//  ListenNowCache.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.05.25.
//

import Foundation
import OSLog
import RFNotifications

public actor ListenNowCache: Sendable {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListenNowCache")
    
    private var items = [PlayableItem]()
    
    private var currentProgressIDs = [String]()
    private var unavailableProgressIDs = [String]()
    
    private var isEmpty = false
    
    private init() {
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
        let entities = try await PersistenceManager.shared.progress.activeProgressEntities.sorted { $0.lastUpdate > $1.lastUpdate }
        
        guard entities.map(\.id) != currentProgressIDs else {
            return items
        }
        
        let available = entities.filter { !unavailableProgressIDs.contains($0.id) }
        
        if available.isEmpty {
            isEmpty = true
        }
        
        let items = await withTaskGroup {
            for entity in available {
                $0.addTask {
                    try? await ResolveCache.shared.resolve(primaryID: entity.primaryID, groupingID: entity.groupingID, connectionID: entity.connectionID)
                }
            }
            
            return await $0.reduce(into: [PlayableItem]()) {
                if let item = $1 {
                    $0.append(item)
                }
            }
        }
        
        let mapped = entities.map { entity in
            (items.first {
                $0.id.primaryID == entity.primaryID
                && $0.id.groupingID == entity.groupingID
                && $0.id.connectionID == entity.connectionID
            }, entity)
        }
        
        currentProgressIDs = mapped.filter { $0.0 != nil }.map(\.1.id)
        unavailableProgressIDs = mapped.filter { $0.0 == nil }.map(\.1.id)
        
        return mapped.compactMap(\.0)
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
    
    public static let shared = ListenNowCache()
}

