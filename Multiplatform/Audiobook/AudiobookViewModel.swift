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
        await progressEntity.beginReceivingUpdates()
        
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
        guard let authors = await audiobook.authors else {
            return
        }
        
        let authorIDs = await AuthorMenu.mapAuthorIDs(authors, libraryID: library.id)
        
        let audiobooks = Dictionary(uniqueKeysWithValues: await authorIDs.parallelMap { (_, authorID) -> (Author, [Audiobook])? in
            guard let author = try? await AudiobookshelfClient.shared.author(authorId: authorID, libraryID: self.library.id) else {
                return nil
            }
            
            guard author.1.count > 1 else {
                return nil
            }
            
            return (author.0, author.1)
        }.compactMap { $0 })
        
        await MainActor.withAnimation {
            self.sameAuthor = audiobooks
        }
    }
    
    func loadSeries() async {
        let audiobooks = await audiobook.series.parallelMap { series -> Audiobook.ReducedSeries? in
            if series.id != nil {
                return series
            }
            
            guard let id = try? await AudiobookshelfClient.shared.seriesID(name: series.name, libraryID: self.audiobook.libraryID) else {
                return nil
            }
            
            var series = series
            series.id = id
            
            return series
        }.parallelMap { series -> (Audiobook.ReducedSeries, [Audiobook])? in
            guard let series else {
                return nil
            }
            
            guard let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(seriesId: series.id!,
                                                                                     libraryID: self.audiobook.libraryID,
                                                                                     sortOrder: .seriesName,
                                                                                     ascending: true,
                                                                                     limit: nil,
                                                                                     page: nil).0 else {
                return nil
            }
            
            guard audiobooks.count > 1 else {
                return nil
            }
            
            return (series, Audiobook.sort(audiobooks, sortOrder: .seriesName, ascending: true))
        }.compactMap { $0 }
        
        await MainActor.withAnimation {
            self.sameSeries = Dictionary(uniqueKeysWithValues: audiobooks)
        }
    }
    
    func loadNarrators() async {
        guard let narrators = await audiobook.narrators else {
            return
        }
        
        let audiobooks = await Dictionary(uniqueKeysWithValues: narrators.parallelMap { narrator -> (String, [Audiobook])? in
            guard let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(narratorName: narrator, libraryID: self.audiobook.libraryID) else {
                return nil
            }
            
            guard audiobooks.count > 1 else {
                return nil
            }
            
            return (narrator, audiobooks)
        }.compactMap { $0 })
        
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
