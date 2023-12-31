//
//  SwipeActionsModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 13.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct SwipeActionsModifier: ViewModifier {
    let item: PlayableItem
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                let progress = OfflineManager.shared.getProgress(item: item)?.progress ?? 0
                Button {
                    Task {
                        await item.setProgress(finished: progress < 1)
                    }
                } label: {
                    if progress >= 1 {
                        Image(systemName: "minus")
                            .tint(.red)
                    } else {
                        Image(systemName: "checkmark")
                            .tint(.accentColor)
                    }
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if item.offline == .none {
                    Button {
                        Task {
                            if let episode = item as? Episode {
                                try? await OfflineManager.shared.download(episode: episode)
                            } else if let audiobook = item as? Audiobook {
                                try? await OfflineManager.shared.download(audiobook: audiobook)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.down")
                    }
                    .tint(.green)
                } else if item.offline == .downloaded {
                    Button {
                        if let episode = item as? Episode {
                            try? OfflineManager.shared.delete(episodeId: episode.id)
                        } else {
                            try? OfflineManager.shared.delete(audiobookId: item.id)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .tint(.red)
                    }
                }
            }
    }
}
