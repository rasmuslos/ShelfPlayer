//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 14.01.24.
//

import Foundation
import SPBaseKit

extension PlayableItem {
    public func setProgress(finished: Bool) async {
        await OfflineManager.shared.setProgress(item: self, finished: finished)
        
        do {
            if let episode = self as? Episode {
                try await AudiobookshelfClient.shared.setFinished(itemId: episode.podcastId, episodeId: episode.id, finished: finished)
            } else {
                try await AudiobookshelfClient.shared.setFinished(itemId: id, episodeId: nil, finished: finished)
            }
        } catch {
            print("Error while updating progress", error)
        }
    }
}
