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
    @MainActor let progressEntity: ItemProgress
    
    @MainActor var toolbarVisible: Bool
    @MainActor private(set) var dominantColor: Color?
    
    @MainActor private(set) var errorNotify: Bool
    
    @MainActor
    init(episode: Episode) {
        self.episode = episode
        progressEntity = OfflineManager.shared.progressEntity(item: episode)
        
        toolbarVisible = false
        dominantColor = nil
        
        errorNotify = false
    }
}

internal extension EpisodeViewModel {
    func load() async {
        guard let url = await episode.cover?.url else {
            return
        }
        
        guard let colors = try? await RFKVisuals.extractDominantColors(4, url: url), let result = RFKVisuals.determineSaturated(colors.map { $0.color }) else {
            return
        }
        
        await MainActor.withAnimation {
            self.dominantColor = result
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
