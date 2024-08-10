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
        await OfflineManager.shared.setProgress(item: self, finished: finished)
        
        if let episode = self as? Episode {
            try await AudiobookshelfClient.shared.finished(finished, itemId: episode.podcastId, episodeId: episode.id)
        } else {
            try await AudiobookshelfClient.shared.finished(finished, itemId: id, episodeId: nil)
        }
    }
}
