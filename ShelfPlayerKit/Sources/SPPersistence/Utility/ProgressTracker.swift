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

@Observable @MainActor
public class ProgressTracker {
    public let itemID: ItemIdentifier
    
    public private(set) var progress: Percentage
    
    public private(set) var duration: TimeInterval
    public private(set) var currentTime: TimeInterval
    
    public private(set) var startedAt: Date?
    public private(set) var lastUpdate: Date
    public private(set) var finishedAt: Date?
    
    @ObservationIgnored var token: RFNotification.Marker?
    
    init(itemID: ItemIdentifier, progress: Percentage, duration: TimeInterval, currentTime: TimeInterval, startedAt: Date?, lastUpdate: Date, finishedAt: Date?) {
        self.itemID = itemID
        
        self.progress = progress
        
        self.duration = duration
        self.currentTime = currentTime
        
        self.startedAt = startedAt
        self.lastUpdate = lastUpdate
        self.finishedAt = finishedAt
        
        token = nil
    }
    
    public func beginReceivingUpdates() {
        guard token == nil else {
            return
        }
    }
    
    public var isFinished: Bool {
        progress >= 1
    }
}
