//
//  EpisodeViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import RFKVisuals
import ShelfPlayerKit

@Observable
internal final class EpisodeViewModel {
    @MainActor let episode: Episode
    
    @MainActor private(set) var dominantColor: Color?
    
    @MainActor var toolbarVisible: Bool
    @MainActor var sessionsVisible: Bool
    
    @MainActor let progressEntity: ItemProgress
    @MainActor private(set) var sessions: [ListeningSession]
    
    @MainActor private(set) var errorNotify: Bool
    
    @MainActor
    init(episode: Episode) {
        self.episode = episode
        
        dominantColor = nil
        
        toolbarVisible = false
        sessionsVisible = false
        
        sessions = []
        progressEntity = OfflineManager.shared.progressEntity(item: episode)
        
        errorNotify = false
    }
}

internal extension EpisodeViewModel {
    func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.loadSessions() }
            $0.addTask { await self.extractColor() }
            
            await $0.waitForAll()
        }
    }
    
    func toggleFinished() {
        Task {
            do {
                try await episode.finished(progressEntity.progress < 1)
            } catch {
                await MainActor.run {
                    errorNotify.toggle()
                }
            }
        }
    }
    func resetProgress() {
        Task {
            do {
                try await episode.resetProgress()
            } catch {
                await MainActor.run {
                    errorNotify.toggle()
                }
            }
        }
    }
}

private extension EpisodeViewModel {
    func loadSessions() async {
        guard let image = await episode.cover?.systemImage else {
            return
        }
        
        guard let colors = try? await RFKVisuals.extractDominantColors(4, image: image), let result = RFKVisuals.determineMostSaturated(colors.map { $0.color }) else {
            return
        }
        
        await MainActor.withAnimation {
            self.dominantColor = result
        }
    }
    func extractColor() async {
        guard let sessions = try? await AudiobookshelfClient.shared.listeningSessions(for: episode.podcastId, episodeID: episode.id) else {
            return
        }
        
        await MainActor.run {
            self.sessions = sessions
        }
    }
}
