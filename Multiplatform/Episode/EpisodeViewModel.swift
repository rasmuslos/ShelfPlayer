//
//  EpisodeViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import RFVisuals
import ShelfPlayerKit

@Observable @MainActor
final class EpisodeViewModel {
    let episode: Episode
    var library: Library!
    
    var toolbarVisible: Bool
    var sessionsVisible: Bool
    
    private(set) var dominantColor: Color?
    
    private(set) var sessions: [SessionPayload]
    private(set) var notifyError: Bool
    
    private(set) var progressEntity: ProgressEntity.UpdatingProgressEntity?
    
    init(episode: Episode) {
        self.episode = episode
        library = nil
        
        toolbarVisible = false
        sessionsVisible = false
        
        dominantColor = nil
        
        sessions = []
        notifyError = false
    }
}

extension EpisodeViewModel {
    nonisolated func load() {
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await self.loadSessions() }
                $0.addTask { await self.extractDominantColor() }
                
                $0.addTask {
                    let progressEntity = await PersistenceManager.shared.progress[self.episode.id].updating
                    
                    await MainActor.withAnimation {
                        self.progressEntity = progressEntity
                    }
                }
                
                await $0.waitForAll()
            }
        }
    }
}

private extension EpisodeViewModel {
    nonisolated func extractDominantColor() async {
        guard let image = await episode.id.platformCover,
              let colors = try? await RFKVisuals.extractDominantColors(4, image: image) else {
            return
        }
        
        let filtered = RFKVisuals.brightnessExtremeFilter(colors.map { $0.color }, threshold: 0.1)
        
        guard let result = RFKVisuals.determineMostSaturated(filtered) else {
            return
        }
        
        await MainActor.withAnimation {
            self.dominantColor = result
        }
    }
    
    nonisolated func loadSessions() async {
        guard let sessions = try? await ABSClient[episode.id.connectionID].listeningSessions(with: episode.id) else {
            await MainActor.run {
                notifyError.toggle()
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.sessions = sessions
        }
    }
}
