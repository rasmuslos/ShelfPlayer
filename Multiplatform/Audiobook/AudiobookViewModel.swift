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

@Observable
final internal class AudiobookViewModel {
    @MainActor var audiobook: Audiobook
    @MainActor var libraryId: String!
    
    @MainActor private(set) var dominantColor: Color
    @MainActor var navigationBarVisible: Bool
    
    @MainActor var chapters: [PlayableItem.Chapter]
    @MainActor var authorID: String?
    
    @MainActor private(set) var sameAuthor: [Audiobook]
    @MainActor private(set) var sameSeries: [Audiobook]
    @MainActor private(set) var sameNarrator: [Audiobook]
    
    @MainActor
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        libraryId = audiobook.libraryId
        
        dominantColor = .accentColor
        navigationBarVisible = false
        
        chapters = []
        authorID = nil
        
        sameAuthor = []
        sameSeries = []
        sameNarrator = []
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
    
    private func loadAudiobook() async {
        if let (item, _, chapters) = try? await AudiobookshelfClient.shared.item(itemId: audiobook.id, episodeId: nil) {
            await MainActor.withAnimation {
                self.audiobook = item as! Audiobook
                self.chapters = chapters
            }
        }
    }
    
    private func loadAuthor() async {
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
    
    private func loadSeries() async {
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
    
    private func loadNarrator() async {
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
    
    private func extractColor() async {
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
