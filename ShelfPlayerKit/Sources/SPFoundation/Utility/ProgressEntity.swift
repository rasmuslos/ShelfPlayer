//
//  ProgressEntity.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 17.09.24.
//

import Foundation
import SwiftUI
import RFNotifications
import SPFoundation

public struct ProgressEntity: Sendable {
    public let id: String
    public let itemID: ItemIdentifier
    
    public let progress: Percentage
    
    public let duration: TimeInterval
    public let currentTime: TimeInterval
    
    public let startedAt: Date?
    public let lastUpdate: Date
    public let finishedAt: Date?
    
    public init(id: String, itemID: ItemIdentifier, progress: Percentage, duration: TimeInterval, currentTime: TimeInterval, startedAt: Date?, lastUpdate: Date, finishedAt: Date?) {
        self.id = id
        self.itemID = itemID
        
        self.progress = progress
        
        self.duration = duration
        self.currentTime = currentTime
        
        self.startedAt = startedAt
        self.lastUpdate = lastUpdate
        self.finishedAt = finishedAt
    }
    
    public var isFinished: Bool {
        progress >= 1
    }
    
    @MainActor
    var updating: UpdatingProgressEntity {
        .init(id: id,
              itemID: itemID,
              progress: progress,
              duration: duration,
              currentTime: currentTime,
              startedAt: startedAt,
              lastUpdate: lastUpdate,
              finishedAt: finishedAt)
    }
    
    @Observable @MainActor
    public final class UpdatingProgressEntity {
        public let id: String
        public let itemID: ItemIdentifier
        
        public var progress: Percentage
        
        public var duration: TimeInterval
        public var currentTime: TimeInterval
        
        public var startedAt: Date?
        public var lastUpdate: Date
        public var finishedAt: Date?
        
        @ObservationIgnored nonisolated(unsafe) var marker: RFNotification.Marker?
        
        init(id: String, itemID: ItemIdentifier, progress: Percentage, duration: TimeInterval, currentTime: TimeInterval, startedAt: Date?, lastUpdate: Date, finishedAt: Date?) {
            self.id = id
            self.itemID = itemID
            
            self.progress = progress
            
            self.duration = duration
            self.currentTime = currentTime
            
            self.startedAt = startedAt
            self.lastUpdate = lastUpdate
            self.finishedAt = finishedAt
            
            marker = RFNotification[.progressEntityUpdated].subscribe { [weak self] in
                self?.progress = $0.progress
                
                self?.duration = $0.duration
                self?.currentTime = $0.currentTime
                
                self?.startedAt = $0.startedAt
                self?.lastUpdate = $0.lastUpdate
                self?.finishedAt = $0.finishedAt
            }
        }
        
        deinit {
            marker?()
        }
        
        public var isFinished: Bool {
            progress >= 1
        }
    }
}
