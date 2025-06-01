//
//  EpisodeViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import OSLog
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class EpisodeViewModel {
    let episode: Episode
    var library: Library!
    
    var toolbarVisible: Bool
    var sessionsVisible: Bool
    
    private(set) var dominantColor: Color?
    
    let sessionLoader: SessionLoader
    
    private(set) var notifyError: Bool
    
    init(episode: Episode) {
        self.episode = episode
        library = nil
        
        toolbarVisible = false
        sessionsVisible = false
        
        dominantColor = nil
        
        sessionLoader = .init(filter: .itemID(episode.id))
        
        notifyError = false
    }
}

extension EpisodeViewModel {
    nonisolated func load(refresh: Bool) {
        Task {
            await withTaskGroup {
                $0.addTask { await self.extractDominantColor() }
                
                if refresh {
                    $0.addTask { await self.sessionLoader.refresh() }
                    
                    $0.addTask {
                        try? await ShelfPlayer.refreshItem(itemID: self.episode.id)
                        self.load(refresh: false)
                    }
                }
            }
        }
    }
}

private extension EpisodeViewModel {
    nonisolated func extractDominantColor() async {
        let color = await PersistenceManager.shared.item.dominantColor(of: episode.id)
        
        await MainActor.withAnimation {
            self.dominantColor = color
        }
    }
}
