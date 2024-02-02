//
//  SwipeActionsModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 13.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPOfflineExtended

struct SwipeActionsModifier: ViewModifier {
    let item: PlayableItem
    let entity: OfflineProgress
    let offlineTracker: ItemOfflineTracker
    
    @MainActor
    init(item: PlayableItem) {
        self.item = item
        
        entity = OfflineManager.shared.requireProgressEntity(item: item)
        offlineTracker = item.offlineTracker
    }
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                
                Button {
                    Task {
                        await item.setProgress(finished: entity.progress < 1)
                    }
                } label: {
                    if entity.progress >= 1 {
                        Image(systemName: "minus")
                            .tint(.red)
                    } else {
                        Image(systemName: "checkmark")
                            .tint(.accentColor)
                    }
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if offlineTracker.status == .none {
                    Button {
                        Task {
                            if let episode = item as? Episode {
                                try? await OfflineManager.shared.download(episodeId: episode.id, podcastId: episode.podcastId)
                            } else if let audiobook = item as? Audiobook {
                                try? await OfflineManager.shared.download(audiobookId: audiobook.id)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.down")
                    }
                    .tint(.green)
                } else if offlineTracker.status == .downloaded {
                    Button {
                        if let episode = item as? Episode {
                            OfflineManager.shared.delete(episodeId: episode.id)
                        } else {
                            OfflineManager.shared.delete(audiobookId: item.id)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .tint(.red)
                    }
                }
            }
    }
}
