//
//  ProgressTracker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.02.25.
//

import SwiftUI
import OSLog
import ShelfPlayerKit

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
        
        RFNotification[.invalidateProgressEntities].subscribe { [weak self] connectionID in
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
    
    nonisolated func load() {
        Task {
            let entity = await ProgressTrackerCache.shared.resolve(itemID)
            
            await MainActor.withAnimation {
                self.progress = entity.progress
                
                self.duration = entity.duration
                self.currentTime = entity.currentTime
                
                self.startedAt = entity.startedAt
                self.lastUpdate = entity.lastUpdate
                self.finishedAt = entity.finishedAt
                
                isValid = true
            }
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

actor ProgressTrackerCache: Sendable {
    private var cache = [ItemIdentifier: ProgressEntity]()
    
    init() {
        Task {
            await setupObservers()
        }
    }
    
    fileprivate func resolve(_ itemID: ItemIdentifier) async -> ProgressEntity {
        if let cached = cache[itemID] {
            return cached
        }
        
        let entity = await PersistenceManager.shared.progress[itemID]
        cache[itemID] = entity
        
        return entity
    }
    func invalidate() {
        cache.removeAll()
    }
    
    func setupObservers() {
        // Not weak: https://github.com/swiftlang/swift/issues/62604
        RFNotification[.invalidateProgressEntities].subscribe { _ in
            self.invalidate()
        }
        
        RFNotification[.progressEntityUpdated].subscribe { connectionID, primaryID, groupingID, entity in
            guard let (itemID, _) = self.cache.first(where: { (itemID, _) in
                itemID.connectionID == connectionID
                && itemID.primaryID == primaryID
                && itemID.groupingID == groupingID
            }) else {
                return
            }
            
            self.cache[itemID] = entity
        }
    }
    
    nonisolated static let shared = ProgressTrackerCache()
}
