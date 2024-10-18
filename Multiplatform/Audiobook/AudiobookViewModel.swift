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
    @MainActor var authorID: String?
    
    @MainActor private(set) var sameAuthor: [Audiobook]
    @MainActor private(set) var sameSeries: [Audiobook]
    @MainActor private(set) var sameNarrator: [Audiobook]
    
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
        authorID = nil
        
        sameAuthor = []
        sameSeries = []
        sameNarrator = []
        
        progressEntity = OfflineManager.shared.progressEntity(item: audiobook)
        offlineTracker = .init(audiobook)
        
        sessions = []
        errorNotify = false
        
        progressEntity.beginReceivingUpdates()
    }
}

internal extension AudiobookViewModel {
    func load() async {
        await progressEntity.beginReceivingUpdates()
        
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.loadAudiobook() }
            
            $0.addTask { await self.loadAuthor() }
            $0.addTask { await self.loadSeries() }
            $0.addTask { await self.loadNarrator() }
            
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
    
    func loadAuthor() async {
        guard let author = await audiobook.authors?.first, let authorId = try? await AudiobookshelfClient.shared.authorID(name: author, libraryID: library.id) else {
            return
        }
        
        await MainActor.withAnimation {
            self.authorID = authorId
        }
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.author(authorId: authorId, libraryID: library.id).1 else {
            return
        }
        
        await MainActor.withAnimation {
            self.sameAuthor = audiobooks
        }
    }
    
    func loadSeries() async {
        let seriesId: String
        
        if let id = await audiobook.series.first?.id {
            seriesId = id
        } else if let name = await audiobook.series.first?.name, let id = try? await AudiobookshelfClient.shared.seriesID(name: name, libraryID: library.id) {
            seriesId = id
        } else {
            return
        }
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(seriesId: seriesId, libraryID: library.id, sortOrder: .series, ascending: true, limit: nil, page: nil).0 else {
            return
        }
        
        await MainActor.withAnimation {
            self.sameSeries = audiobooks
        }
    }
    
    func loadNarrator() async {
        guard let narratorName = await audiobook.narrator else {
            return
        }
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(narratorName: narratorName, libraryID: library.id) else {
            return
        }
        
        await MainActor.withAnimation {
            self.sameNarrator = audiobooks
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
