//
//  NowPlayingWidgetManager.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation
import OSLog
import SPFoundation

final actor NowPlayingWidgetManager: Sendable {
    let logger = Logger(subsystem: "io.rfk.shelfPlayewrKit", category: "NowPlayingWidgetManager")
    
    var activeID: UUID?
    var metadata = [String: Any]()
    
    func suggestUpdate(from id: UUID, item: PlayableItem) {
        guard isActive(id: id) else {
            return
        }
        
        updateWidget()
    }
    func suggestUpdate(from id: UUID, duration: TimeInterval, currentTime: TimeInterval) {
        updateWidget()
    }
    
    func invalidate() {
        activeID = nil
        metadata = [:]
    }
}

private extension NowPlayingWidgetManager {
    func isActive(id: UUID) -> Bool {
        guard activeID == nil || activeID == id else {
            logger.warning("Ignoring update request from \(id) for now playing widget, as another player (\(self.activeID?.uuidString ?? "?")) is already active")
            return false
        }
        
        if activeID == nil {
            activeID = id
        }
        
        return true
    }
    func updateWidget() {
        
    }
}
