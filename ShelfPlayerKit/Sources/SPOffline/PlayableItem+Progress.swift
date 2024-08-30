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
        OfflineManager.shared.finished(finished, item: self)
        try await AudiobookshelfClient.shared.finished(finished, itemId: identifiers.itemID, episodeId: identifiers.episodeID)
    }
    
    func resetProgress() async throws {
        try await AudiobookshelfClient.shared.deleteProgress(itemId: identifiers.itemID, episodeId: identifiers.episodeID)
        try OfflineManager.shared.resetProgressEntity(id: OfflineManager.shared.progressEntity(item: self).id)
    }
}
