//
//  AudiobookViewModel.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SwiftUI
import RFKVisuals
import ShelfPlayerKit
import SPPlayback

@Observable
internal final class AudiobookViewModel {
    @MainActor var audiobook: Audiobook
    @MainActor var library: Library!
    
    @MainActor private(set) var dominantColor: Color?
    
    @MainActor var toolbarVisible: Bool
    @MainActor var chaptersVisible: Bool
    @MainActor var sessionsVisible: Bool
    
    @MainActor var chapters: [PlayableItem.Chapter]
    
    @MainActor private(set) var sameAuthor: [Author: [Audiobook]]
    @MainActor private(set) var sameSeries: [Audiobook.ReducedSeries: [Audiobook]]
    @MainActor private(set) var sameNarrator: [String: [Audiobook]]
    
    @MainActor let progressEntity: ProgressEntity
    @MainActor let offlineTracker: ItemOfflineTracker
    
    @MainActor private(set) var sessions: [ListeningSession]
    @MainActor private(set) var errorNotify: Bool
    
    @MainActor
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        
        dominantColor = nil
        
        toolbarVisible = false
        chaptersVisible = false
        sessionsVisible = false
        
        chapters = []
        
        sameAuthor = [:]
        sameSeries = [:]
        sameNarrator = [:]
        
        progressEntity = OfflineManager.shared.progressEntity(item: audiobook)
        offlineTracker = .init(audiobook)
        
        sessions = []
        errorNotify = false
        
        progressEntity.beginReceivingUpdates()
    }
}

internal extension AudiobookViewModel {
    func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.loadAudiobook() }
            
            $0.addTask { await self.loadAuthors() }
            $0.addTask { await self.loadSeries() }
            $0.addTask { await self.loadNarrators() }
            
            $0.addTask { await self.loadSessions() }
            $0.addTask { await self.extractColor() }
            
            await $0.waitForAll()
        }
    }
    
    func play() {
        Task {
            do {
                try await AudioPlayer.shared.play(audiobook)
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
                try await audiobook.resetProgress()
            } catch {
                await MainActor.run {
                    errorNotify.toggle()
                }
            }
        }
    }
}

private extension AudiobookViewModel {
    func loadAudiobook() async {
        guard let (item, _, chapters) = try? await AudiobookshelfClient.shared.item(itemId: audiobook.id, episodeId: nil) else {
            return
        }
        
        await MainActor.withAnimation {
            self.audiobook = item as! Audiobook
            self.chapters = chapters
        }
    }
    
    func loadAuthors() async {
        var resolved = [Author: [Audiobook]]()
        
        for author in await audiobook.authors {
            do {
                let authorID = try await AudiobookshelfClient.shared.authorID(name: author, libraryID: audiobook.libraryID)
                let (author, audiobooks, _) = try await AudiobookshelfClient.shared.author(authorId: authorID, libraryID: audiobook.libraryID)
                
                resolved[author] = audiobooks
            } catch {
                
            }
        }
        
        await MainActor.withAnimation {
            self.sameAuthor = resolved
        }
    }
    
    func loadSeries() async {
        var resolved = [Audiobook.ReducedSeries: [Audiobook]]()
        
        for series in await audiobook.series {
            do {
                let seriesID: String
                
                if let id = series.id {
                    seriesID = id
                } else {
                    seriesID = try await AudiobookshelfClient.shared.seriesID(name: series.name, libraryID: audiobook.libraryID)
                }
                
                let audiobooks = try await AudiobookshelfClient.shared.audiobooks(seriesID: seriesID, libraryID: self.audiobook.libraryID).0
                resolved[series] = audiobooks
            } catch {
                continue
            }
        }
        
        await MainActor.withAnimation {
            self.sameSeries = resolved
        }
    }
    
    func loadNarrators() async {
        var resolved = [String: [Audiobook]]()
        
        for narrator in await audiobook.narrators {
            do {
                resolved[narrator] = try await AudiobookshelfClient.shared.audiobooks(narratorName: narrator, libraryID: self.audiobook.libraryID)
            } catch {
                continue
            }
        }
        
        await MainActor.withAnimation {
            self.sameNarrator = resolved
        }
    }
    
    func extractColor() async {
        guard let image = await audiobook.cover?.platformImage else {
            return
        }
        
        guard let colors = try? await RFKVisuals.extractDominantColors(4, image: image) else {
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
    
    func loadSessions() async {
        guard let sessions = try? await AudiobookshelfClient.shared.listeningSessions(for: audiobook.id, episodeID: nil) else {
            return
        }
        
        await MainActor.withAnimation {
            self.sessions = sessions
        }
    }
}
