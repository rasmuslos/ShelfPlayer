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
            let entity = await PersistenceManager.shared.progress[itemID]
            
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
