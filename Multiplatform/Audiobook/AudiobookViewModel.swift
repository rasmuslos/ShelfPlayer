//
//  AudiobookViewModel.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SwiftUI
import OSLog
import ShelfPlayerKit
import SPPlayback

@Observable @MainActor
final class AudiobookViewModel: Sendable {
    let logger: Logger
    let signposter: OSSignposter
    
    private(set) var audiobook: Audiobook
    
    var library: Library!
    
    var presentedPDF: Data?
    
    var toolbarVisible: Bool
    var chaptersVisible: Bool
    var sessionsVisible: Bool
    var supplementaryPDFsVisible: Bool
    
    private(set) var dominantColor: Color?
    
    private(set) var chapters: [Chapter]
    private(set) var supplementaryPDFs: [PlayableItem.SupplementaryPDF]
    
    private(set) var sameAuthor: [String: [Audiobook]]
    private(set) var sameSeries: [Audiobook.SeriesFragment: [Audiobook]]
    private(set) var sameNarrator: [String: [Audiobook]]
    
    private(set) var loadingPDF: Bool
    
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
        supplementaryPDFsVisible = false
        
        dominantColor = nil
        
        chapters = []
        supplementaryPDFs = []
        
        sameAuthor = [:]
        sameSeries = [:]
        sameNarrator = [:]
        
        loadingPDF = false
        
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
                
                await $0.waitForAll()
            }
        }
    }
    
    func presentPDF(_ pdf: PlayableItem.SupplementaryPDF) {
        presentedPDF = nil
        loadingPDF = true
        
        loadPDF(pdf)
    }
}

private extension AudiobookViewModel {
    nonisolated func loadPDF(_ pdf: PlayableItem.SupplementaryPDF) {
        Task {
            let audiobookID = await audiobook.id
            
            do {
                let data = try await ABSClient[audiobookID.connectionID].pdf(from: audiobookID, ino: pdf.ino)
                
                await MainActor.withAnimation {
                    notifySuccess.toggle()
                    
                    self.loadingPDF = false
                    self.presentedPDF = data
                }
            } catch {
                await MainActor.run {
                    loadingPDF = false
                    notifyError.toggle()
                }
            }
        }
    }
    
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
        var resolved = [String: [Audiobook]]()
        
        for author in await audiobook.authors {
            do {
                let authorID = try await ABSClient[audiobook.id.connectionID].authorID(from: audiobook.id.libraryID, name: author)
                var (audiobooks, _) = try await ABSClient[audiobook.id.connectionID].audiobooks(filtered: authorID, sortOrder: .released, ascending: true, limit: 100, page: 0)
                
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
                    seriesID = try await ABSClient[audiobook.id.connectionID].seriesID(from: library.id, name: series.name)
                }
                
                var (audiobooks, _) = try await ABSClient[audiobook.id.connectionID].audiobooks(filtered: seriesID, sortOrder: nil, ascending: nil, limit: 20, page: 0)
                
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
    
    nonisolated func extractColor() async {
        let color = await PersistenceManager.shared.item.dominantColor(of: audiobook.id)
        
        await MainActor.withAnimation {
            self.dominantColor = color
        }
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
