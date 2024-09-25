//
//  ProgressEntity.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 17.09.24.
//

import Foundation
import SwiftUI
import SPFoundation

@Observable
public class ProgressEntity {
    public let id: String
    public let itemID: String
    public let episodeID: String?
    
    public private(set) var progress: Percentage
    
    public private(set) var duration: TimeInterval
    public private(set) var currentTime: TimeInterval
    
    public private(set) var startedAt: Date?
    public private(set) var lastUpdate: Date
    public private(set) var finishedAt: Date?
    
    @ObservationIgnored var token: Any?
    
    init(id: String, itemID: String, episodeID: String?, progress: Percentage, duration: TimeInterval, currentTime: TimeInterval, startedAt: Date?, lastUpdate: Date, finishedAt: Date?) {
        self.id = id
        self.itemID = itemID
        self.episodeID = episodeID
        
        self.progress = progress
        
        self.duration = duration
        self.currentTime = currentTime
        
        self.startedAt = startedAt
        self.lastUpdate = lastUpdate
        self.finishedAt = finishedAt
        
        token = nil
    }
    
    deinit {
        guard let token else {
            return
        }
        
        NotificationCenter.default.removeObserver(token)
    }
    
    public func beginReceivingUpdates() {
        guard token == nil else {
            return
        }
        
        token = NotificationCenter.default.addObserver(forName: Self.progressUpdatedNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self else {
                return
            }
            
            let id = convertIdentifier(itemID: itemID, episodeID: episodeID)
            
            guard notification.object as? String == id || notification.object == nil else {
                return
            }
            
            let updated = OfflineManager.shared.progressEntity(itemID: self.itemID, episodeID: self.episodeID)
            
            self.progress = updated.progress
            
            self.duration = updated.duration
            self.currentTime = updated.currentTime
            
            self.startedAt = updated.startedAt
            self.lastUpdate = updated.lastUpdate
            self.finishedAt = updated.finishedAt
        }
    }
    
    public var isFinished: Bool {
        progress >= 1
    }
    
    static let progressUpdatedNotification = Notification.Name("io.rfk.shelfPlayer.progressUpdatedNotification")
}
