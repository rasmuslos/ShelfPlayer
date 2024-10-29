//
//  File.swift
//
//
//  Created by Rasmus Krämer on 14.01.24.
//

import Foundation
import SwiftUI
import SPFoundation
import SPNetwork

public extension PlayableItem {
    func finished(_ finished: Bool) async throws {
        let success: Bool
        
        do {
            try await AudiobookshelfClient.shared.finished(finished, itemId: identifiers.itemID, episodeId: identifiers.episodeID)
            success = true
        } catch {
            success = false
        }
        
        OfflineManager.shared.finished(finished, item: self, synced: success)
        
        NotificationCenter.default.post(name: Self.finishedNotification, object: nil, userInfo: [
            "itemID": identifiers.itemID,
            "episodeID": identifiers.episodeID as Any,
            
            "finished": finished,
        ])
    }
    
    func resetProgress() async throws {
        try OfflineManager.shared.resetProgressEntity(itemID: identifiers.itemID, episodeID: identifiers.episodeID)
        try await AudiobookshelfClient.shared.deleteProgress(itemId: identifiers.itemID, episodeId: identifiers.episodeID)
    }
    
    static let finishedNotification = Notification.Name("io.rfk.shelfPlayer.item.finished")
}
