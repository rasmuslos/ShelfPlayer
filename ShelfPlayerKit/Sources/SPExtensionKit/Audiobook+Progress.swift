//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 14.01.24.
//

import Foundation
import SPBaseKit

#if canImport(SPOfflineKit)
import SPOfflineKit
#endif

extension PlayableItem {
    public func setProgress(finished: Bool) async {
        do {
            if let episode = self as? Episode {
                try await AudiobookshelfClient.shared.setFinished(itemId: episode.podcastId, episodeId: episode.id, finished: finished)
            } else {
                try await AudiobookshelfClient.shared.setFinished(itemId: id, episodeId: nil, finished: finished)
            }
            
            #if canImport(SPOfflineKit)
            await OfflineManager.shared.setProgress(item: self, finished: finished)
            #endif
        } catch {
            print("Error while updating progress", error)
        }
    }
}
