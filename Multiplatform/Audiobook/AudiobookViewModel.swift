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
final internal class AudiobookViewModel {
    @MainActor var audiobook: Audiobook
    @MainActor var libraryId: String!
    
    @MainActor private(set) var dominantColor: Color?
    @MainActor var navigationBarVisible: Bool
    
    @MainActor var chapters: [PlayableItem.Chapter]
    @MainActor var authorID: String?
    
    @MainActor private(set) var sameAuthor: [Audiobook]
    @MainActor private(set) var sameSeries: [Audiobook]
    @MainActor private(set) var sameNarrator: [Audiobook]
    
    @MainActor private(set) var errorNotify: Bool
    @MainActor private(set) var progressEntity: ItemProgress
    
    @MainActor
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        libraryId = audiobook.libraryId
        
        dominantColor = nil
        navigationBarVisible = false
        
        chapters = []
        authorID = nil
        
        sameAuthor = []
        sameSeries = []
        sameNarrator = []
        
        errorNotify = false
        progressEntity = OfflineManager.shared.progressEntity(item: audiobook)
        
        progressEntity.beginReceivingUpdates()
    }
}

internal extension AudiobookViewModel {
    func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.loadAudiobook() }
            
            $0.addTask { await self.loadAuthor() }
            $0.addTask { await self.loadSeries() }
            $0.addTask { await self.loadNarrator() }
            
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
        if let (item, _, chapters) = try? await AudiobookshelfClient.shared.item(itemId: audiobook.id, episodeId: nil) {
            await MainActor.withAnimation {
                self.audiobook = item as! Audiobook
                self.chapters = chapters
            }
        }
    }
    
    func loadAuthor() async {
        guard let author = await audiobook.author, let authorId = try? await AudiobookshelfClient.shared.authorID(name: author, libraryId: libraryId) else {
            return
        }
        
        await MainActor.withAnimation {
            self.authorID = authorId
        }
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.author(authorId: authorId, libraryId: libraryId).1 else {
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
        } else if let name = await audiobook.series.first?.name, let id = try? await AudiobookshelfClient.shared.seriesID(name: name, libraryId: libraryId) {
            seriesId = id
        } else {
            return
        }
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(seriesId: seriesId, libraryId: libraryId) else {
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
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(narratorName: narratorName, libraryId: libraryId) else {
            return
        }
        
        await MainActor.withAnimation {
            self.sameNarrator = audiobooks
        }
    }
    
    func extractColor() async {
        guard let url = await audiobook.cover?.url else {
            return
        }
        
        guard let colors = try? await RFKVisuals.extractDominantColors(4, url: url), let result = RFKVisuals.determineSaturated(colors.map { $0.color }) else {
            return
        }
        
        await MainActor.withAnimation {
            self.dominantColor = result
        }
    }
}
