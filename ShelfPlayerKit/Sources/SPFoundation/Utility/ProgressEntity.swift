//
//  ProgressEntity.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 17.09.24.
//

import Foundation
import SwiftUI
import RFNotifications

public struct ProgressEntity: Sendable {
    public let id: String
    
    public let connectionID: String
    
    public let primaryID: String
    public let groupingID: String?
    
    public let progress: Percentage
    
    public let duration: TimeInterval?
    public let currentTime: TimeInterval
    
    public let startedAt: Date?
    public let lastUpdate: Date
    public let finishedAt: Date?
    
    public init(id: String, connectionID: String, primaryID: String, groupingID: String?, progress: Percentage, duration: TimeInterval?, currentTime: TimeInterval, startedAt: Date?, lastUpdate: Date, finishedAt: Date?) {
        self.id = id
        self.connectionID = connectionID
        
        self.primaryID = primaryID
        self.groupingID = groupingID
        
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
    public var updating: UpdatingProgressEntity {
        .init(id: id,
              connectionID: connectionID,
              primaryID: primaryID,
              groupingID: groupingID,
              progress: progress,
              duration: duration,
              currentTime: currentTime,
              startedAt: startedAt,
              lastUpdate: lastUpdate,
              finishedAt: finishedAt)
    }
    
    @Observable @MainActor
    public final class UpdatingProgressEntity {
        public var id: String
        public let connectionID: String
        
        public let primaryID: String
        public let groupingID: String?
        
        public var progress: Percentage
        
        public var duration: TimeInterval?
        public var currentTime: TimeInterval
        
        public var startedAt: Date?
        public var lastUpdate: Date
        public var finishedAt: Date?
        
        public var isValid: Bool
        
        init(id: String, connectionID: String, primaryID: String, groupingID: String?, progress: Percentage, duration: TimeInterval?, currentTime: TimeInterval, startedAt: Date?, lastUpdate: Date, finishedAt: Date?) {
            self.id = id
            self.connectionID = connectionID
            
            self.primaryID = primaryID
            self.groupingID = groupingID
            
            self.progress = progress
            
            self.duration = duration
            self.currentTime = currentTime
            
            self.startedAt = startedAt
            self.lastUpdate = lastUpdate
            self.finishedAt = finishedAt
            
            isValid = true
            
            RFNotification[.progressEntityUpdated].subscribe { [weak self] in
                guard $0.connectionID == connectionID && $0.primaryID == primaryID && $0.groupingID == groupingID else { return }
                
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
            RFNotification[.invalidateProgressEntities].subscribe { [weak self] in
                guard $0 == nil || connectionID == $0 else {
                    return
                }
                
                Task {
                    // TODO: 
                    // let entity = try await PersistenceManager.s
                }
            }
        }
        
        public var isFinished: Bool {
            progress >= 1
        }
    }
}
