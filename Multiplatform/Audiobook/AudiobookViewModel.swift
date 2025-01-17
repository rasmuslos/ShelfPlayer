//
//  AudiobookViewModel.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SwiftUI
import OSLog
import RFVisuals
import RFNotifications
import ShelfPlayerKit
import SPPlayback

@Observable @MainActor
final class AudiobookViewModel: Sendable {
    let logger: Logger
    let signposter: OSSignposter
    
    private(set) var audiobook: Audiobook
    
    var library: Library!
    
    var toolbarVisible: Bool
    var chaptersVisible: Bool
    var sessionsVisible: Bool
    
    private(set) var dominantColor: Color?
    
    private(set) var chapters: [Chapter]
    private(set) var supplementaryPDFs: [PlayableItem.SupplementaryPDF]
    
    private(set) var sameAuthor: [Author: [Audiobook]]
    private(set) var sameSeries: [Audiobook.SeriesFragment: [Audiobook]]
    private(set) var sameNarrator: [String: [Audiobook]]
    
    private(set) var progressEntity: ProgressEntity.UpdatingProgressEntity?
    private(set) var downloadTracker: DownloadTracker?
    
    private(set) var sessions: [SessionPayload]
    
    private(set) var notifyError: Bool
    private(set) var notifySuccess: Bool
    
    init(_ audiobook: Audiobook) {
        logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "AudiobookViewModel")
        signposter = OSSignposter(logger: logger)
        
        self.audiobook = audiobook
        
        toolbarVisible = false
        chaptersVisible = false
        sessionsVisible = false
        
        dominantColor = nil
        
        chapters = []
        supplementaryPDFs = []
        
        sameAuthor = [:]
        sameSeries = [:]
        sameNarrator = [:]
        
        sessions = []
        
        notifyError = false
        notifySuccess = false
    }
}

extension AudiobookViewModel {
    nonisolated func load() {
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await self.loadAudiobook() }
                
                $0.addTask { await self.loadAuthors() }
                $0.addTask { await self.loadSeries() }
                $0.addTask { await self.loadNarrators() }
                
                $0.addTask { await self.loadSessions() }
                $0.addTask { await self.extractColor() }
                
                $0.addTask {
                    let progressEntity = await PersistenceManager.shared.progress[self.audiobook.id].updating
                    
                    await MainActor.withAnimation {
                        self.progressEntity = progressEntity
                    }
                }
                
                await $0.waitForAll()
            }
        }
    }
    
    nonisolated func play() {
        Task {
            do {
                try await AudioPlayer.shared.play(audiobook)
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
        }
    }
    
    nonisolated func resetProgress() {
        Task {
            do {
                try await PersistenceManager.shared.progress.delete(itemID: audiobook.id)
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
        }
    }
}

private extension AudiobookViewModel {
    nonisolated func loadAudiobook() async {
        guard let (item, _, chapters, supplementaryPDFs) = try? await ABSClient[audiobook.id.connectionID].playableItem(itemID: audiobook.id) else {
            return
        }
        
        await MainActor.withAnimation {
            self.audiobook = item as! Audiobook
            self.chapters = chapters
            self.supplementaryPDFs = supplementaryPDFs
        }
    }
    
    nonisolated func loadAuthors() async {
        let current = await audiobook
        var resolved = [Author: [Audiobook]]()
        
        for author in await audiobook.authors {
            do {
                let authorID = try await ABSClient[audiobook.id.connectionID].authorID(from: audiobook.id.libraryID, name: author)
                var (author, audiobooks, _) = try await ABSClient[audiobook.id.connectionID].author(with: authorID)
                
                audiobooks = audiobooks.filter { $0 != current }
                
                guard !audiobooks.isEmpty else {
                    continue
                }
                
                resolved[author] = audiobooks
            } catch {
                logger.warning("Failed to load author \(author): \(error)")
                
                await MainActor.run {
                    notifyError.toggle()
                }
            }
        }
        
        await MainActor.withAnimation {
            self.sameAuthor = resolved
        }
    }
    
    nonisolated func loadSeries() async {
        let current = await audiobook
        var resolved = [Audiobook.SeriesFragment: [Audiobook]]()
        
        for series in await audiobook.series {
            do {
                let seriesID: ItemIdentifier
                
                if let id = series.id {
                    seriesID = id
                } else {
                    seriesID = try await ABSClient[audiobook.id.connectionID].seriesID(name: series.name, libraryID: audiobook.id.libraryID)
                }
                
                var (audiobooks, _) = try await ABSClient[audiobook.id.connectionID].audiobooks(series: seriesID, limit: 200, page: 0)
                
                audiobooks = audiobooks.filter { $0 != current }
                
                guard !audiobooks.isEmpty else {
                    continue
                }
                
                resolved[series] = audiobooks
            } catch {
                logger.warning("Failed to load series \(series.name): \(error)")
                
                await MainActor.run {
                    notifyError.toggle()
                }
            }
        }
        
        await MainActor.withAnimation {
            self.sameSeries = resolved
        }
    }
    
    nonisolated func loadNarrators() async {
        let current = await audiobook
        var resolved = [String: [Audiobook]]()
        
        for narrator in await audiobook.narrators {
            do {
                var audiobooks = try await ABSClient[audiobook.id.connectionID].audiobooks(from: audiobook.id.libraryID, narratorName: narrator, page: 0, limit: 200)
                
                audiobooks = audiobooks.filter { $0 != current }
                
                guard !audiobooks.isEmpty else {
                    continue
                }
                
                resolved[narrator] = audiobooks
            } catch {
                logger.warning("Failed to load narrator \(narrator): \(error)")
                
                await MainActor.run {
                    notifyError.toggle()
                }
            }
        }
        
        await MainActor.withAnimation {
            self.sameNarrator = resolved
        }
    }
    
    func extractColor() async {
        /*
        guard let image = await audiobook.cover?.platformImage else {
            return
        }
         */
        
        /*
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
         */
    }
    
    nonisolated func loadSessions() async {
        guard let sessions = try? await ABSClient[audiobook.id.connectionID].listeningSessions(with: audiobook.id) else {
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
