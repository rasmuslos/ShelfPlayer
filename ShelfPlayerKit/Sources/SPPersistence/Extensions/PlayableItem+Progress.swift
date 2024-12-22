//
//  File.swift
//
//
//  Created by Rasmus Krämer on 14.01.24.
//

import Foundation
import SwiftUI
import Combine
import SPFoundation
import SPNetwork

public extension PlayableItem {
    func finished(_ finished: Bool) async throws {
        let success: Bool
        
        do {
            try await AudiobookshelfClient.shared.finished(finished, id: id)
            success = true
        } catch {
            success = false
        }
        
        OfflineManager.shared.finished(finished, item: self, synced: success)
    }
    
    func resetProgress() async throws {
        try OfflineManager.shared.resetProgressEntity(itemID: id)
        try await AudiobookshelfClient.shared.deleteProgress(itemID: id)
    }
    
    static let finishedNotification = Notification.Name("io.rfk.shelfPlayer.item.finished")
}
