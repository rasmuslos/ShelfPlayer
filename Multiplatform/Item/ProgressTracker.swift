//
//  ProgressTracker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.02.25.
//

import SwiftUI
import OSLog
import ShelfPlayback

@Observable @MainActor
final class ProgressTracker {
    let itemID: ItemIdentifier
    
    var progress: Percentage?
    
    var duration: TimeInterval?
    var currentTime: TimeInterval?
    
    var startedAt: Date?
    var lastUpdate: Date?
    var finishedAt: Date?
    
    var isValid: Bool?
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        
        load()
        
        RFNotification[.invalidateProgressCache].subscribe { [weak self] connectionID in
            guard connectionID == nil || connectionID == itemID.connectionID else {
                return
            }
            
            self?.load()
        }
        
        RFNotification[.progressEntityUpdated].subscribe { [weak self] in
            guard $0.connectionID == itemID.connectionID && $0.primaryID == itemID.primaryID && $0.groupingID == itemID.groupingID else {
                return
            }
            
            guard let entity = $0.3 else {
                self?.progress = 0
                self?.currentTime = 0
                
                self?.startedAt = nil
                self?.finishedAt = nil
                
                self?.lastUpdate = .now
                self?.isValid = false
                
                return
            }
            
            self?.progress = entity.progress
            
            self?.duration = entity.duration
            self?.currentTime = entity.currentTime
            
            self?.startedAt = entity.startedAt
            self?.lastUpdate = entity.lastUpdate
            self?.finishedAt = entity.finishedAt
        }
    }
    
    func load() {
        Task {
            let entity = await ProgressCache.shared.entity(for: itemID)
            
            self.progress = entity.progress
            
            self.duration = entity.duration
            self.currentTime = entity.currentTime
            
            self.startedAt = entity.startedAt
            self.lastUpdate = entity.lastUpdate
            self.finishedAt = entity.finishedAt
            
            isValid = true
        }
    }
    
    public var isFinished: Bool? {
        if let progress {
            progress >= 1
        } else {
            nil
        }
    }
}

private actor ProgressCache: Sendable {
    var cached = [ItemIdentifier: Task<ProgressEntity, Never>]()
    
    private init() {
        RFNotification[.invalidateProgressEntities].subscribe { [weak self] connectionID in
            Task {
                await self?.invalidateAndPropagate(connectionID: connectionID)
            }
        }
        RFNotification[.progressEntityUpdated].subscribe { [weak self] payload in
            Task {
                await self?.invalidate(connectionID: payload.connectionID, primaryID: payload.primaryID, groupingID: payload.groupingID)
            }
        }
    }
    
    func entity(for itemID: ItemIdentifier) async -> ProgressEntity {
        if cached[itemID] == nil {
            cached[itemID] = Task.detached {
                await PersistenceManager.shared.progress[itemID]
            }
        }
        
        return await cached[itemID]!.value
    }
    
    private func invalidateAndPropagate(connectionID: ItemIdentifier.ConnectionID?) async {
        guard let connectionID else {
            cached.removeAll()
            return
        }
        
        let keys = cached.keys.filter {
            $0.connectionID == connectionID
        }
        
        for key in keys {
            cached[key] = nil
        }
        
        await RFNotification[.invalidateProgressCache].send(payload: connectionID)
    }
    private func invalidate(connectionID: ItemIdentifier.ConnectionID, primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?) {
        let keys = cached.keys.filter {
            $0.connectionID == connectionID
                && $0.primaryID == primaryID
                && $0.groupingID == groupingID
        }
        
        for key in keys {
            cached[key] = nil
        }
    }
    
    nonisolated static let shared = ProgressCache()
}
