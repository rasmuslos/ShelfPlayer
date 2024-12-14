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
    @MainActor var library: Library!
    
    @MainActor private(set) var dominantColor: Color?
    
    @MainActor var toolbarVisible: Bool
    @MainActor var sessionsVisible: Bool
    
    @MainActor private(set) var sessions: [ListeningSession]
    @MainActor private(set) var errorNotify: Bool
    
    @MainActor let progressEntity: ProgressEntity
    
    @MainActor
    init(episode: Episode) {
        self.episode = episode
        library = nil
        
        dominantColor = nil
        
        toolbarVisible = false
        sessionsVisible = false
        
        sessions = []
        errorNotify = false
        
        progressEntity = OfflineManager.shared.progressEntity(item: episode)
        progressEntity.beginReceivingUpdates()
    }
}

internal extension EpisodeViewModel {
    func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.loadSessions() }
            $0.addTask { await self.extractDominantColor() }
            
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
    func extractDominantColor() async {
        guard let image = await episode.cover?.platformImage else {
            return
        }
        
        guard let colors = try? await RFKVisuals.extractDominantColors(4, image: image) else {
            return
        }
        
        let result = colors.sorted { $0.percentage > $1.percentage }.first?.color
        
        await MainActor.withAnimation {
            self.dominantColor = result
        }
    }
    func loadSessions() async {
        if await library.type == .offline {
            return
        }
        
        guard let sessions = try? await AudiobookshelfClient.shared.listeningSessions(for: episode.podcastId, episodeID: episode.id) else {
            return
        }
        
        await MainActor.withAnimation {
            self.sessions = sessions
        }
    }
}
