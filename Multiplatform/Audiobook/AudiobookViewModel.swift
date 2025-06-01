//
//  AudiobookViewModel.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SwiftUI
import OSLog
import ShelfPlayback

@Observable @MainActor
final class AudiobookViewModel: Sendable {
    let logger: Logger
    let signposter: OSSignposter
    
    private(set) var audiobook: Audiobook
    
    var library: Library!
    
    var presentedPDF: Data?
    
    var toolbarVisible: Bool
    var bookmarksVisible: Bool
    var chaptersVisible: Bool
    var sessionsVisible: Bool
    var supplementaryPDFsVisible: Bool
    
    private(set) var dominantColor: Color?
    
    private(set) var chapters: [Chapter]
    private(set) var supplementaryPDFs: [PlayableItem.SupplementaryPDF]
    
    private(set) var sameAuthor: [(String, [Audiobook])]
    private(set) var sameSeries: [(Audiobook.SeriesFragment, [Audiobook])]
    private(set) var sameNarrator: [(String, [Audiobook])]
    
    private(set) var loadingPDF: Bool
    
    private(set) var bookmarks: [Bookmark]
    
    let sessionLoader: SessionLoader
    
    private(set) var notifyError: Bool
    private(set) var notifySuccess: Bool
    
    init(_ audiobook: Audiobook) {
        logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "AudiobookViewModel")
        signposter = OSSignposter(logger: logger)
        
        self.audiobook = audiobook
        
        toolbarVisible = false
        bookmarksVisible = false
        chaptersVisible = false
        sessionsVisible = false
        supplementaryPDFsVisible = false
        
        dominantColor = nil
        
        chapters = []
        supplementaryPDFs = []
        
        sameAuthor = []
        sameSeries = []
        sameNarrator = []
        
        loadingPDF = false
        
        bookmarks = []
        
        sessionLoader = .init(filter: .itemID(audiobook.id))
        
        notifyError = false
        notifySuccess = false
    }
}

extension AudiobookViewModel {
    nonisolated func load(refresh: Bool) {
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await self.loadAudiobook() }
                
                $0.addTask { await self.loadAuthors() }
                $0.addTask { await self.loadSeries() }
                $0.addTask { await self.loadNarrators() }
                
                $0.addTask { await self.loadBookmarks() }
                
                $0.addTask { await self.extractColor() }
                
                if refresh {
                    $0.addTask { await self.sessionLoader.refresh() }
                    
                    $0.addTask {
                        try? await ShelfPlayer.refreshItem(itemID: self.audiobook.id)
                        self.load(refresh: false)
                    }
                }
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
                await MainActor.withAnimation {
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
        let resolved = await withTaskGroup {
            let audiobook = await audiobook
            
            for author in audiobook.authors {
                $0.addTask { () -> (String, [Audiobook])? in
                    do {
                        let authorID = try await ABSClient[self.audiobook.id.connectionID].authorID(from: self.audiobook.id.libraryID, name: author)
                        var (audiobooks, _) = try await ABSClient[self.audiobook.id.connectionID].audiobooks(filtered: authorID, sortOrder: .released, ascending: true, limit: 100, page: 0)
                        
                        audiobooks = audiobooks.filter { $0 != audiobook }
                        
                        guard !audiobooks.isEmpty else {
                            return nil
                        }
                        
                        return (author, audiobooks)
                    } catch {
                        return nil
                    }
                }
            }
            
            return await $0.reduce(into: [String: [Audiobook]]()) {
                guard let (author, audiobooks) = $1 else {
                    return
                }
                
                $0[author] = audiobooks
            }.sorted(by: { $0.0 < $1.0 })
        }
        
        await MainActor.withAnimation {
            self.sameAuthor = resolved
        }
    }
    
    nonisolated func loadSeries() async {
        let resolved = await withTaskGroup {
            let audiobook = await audiobook
            
            for series in audiobook.series {
                $0.addTask { () -> (Audiobook.SeriesFragment, [Audiobook])? in
                    do {
                        let seriesID: ItemIdentifier
                        
                        if let id = series.id {
                            seriesID = id
                        } else {
                            seriesID = try await ABSClient[audiobook.id.connectionID].seriesID(from: self.library.id, name: series.name)
                        }
                        
                        var (audiobooks, _) = try await ABSClient[audiobook.id.connectionID].audiobooks(filtered: seriesID, sortOrder: nil, ascending: nil, limit: 20, page: 0)
                        
                        audiobooks = audiobooks.filter { $0 != audiobook }
                        
                        guard !audiobooks.isEmpty else {
                            return nil
                        }
                        
                        return (series, audiobooks)
                    } catch {
                        return nil
                    }
                }
            }
            
            return await $0.reduce(into: [Audiobook.SeriesFragment: [Audiobook]]()) {
                guard let (series, audiobooks) = $1 else {
                    return
                }
                
                $0[series] = audiobooks
            }.sorted(by: { $0.0.name < $1.0.name })
        }
        
        await MainActor.withAnimation {
            self.sameSeries = resolved
        }
    }
    
    nonisolated func loadNarrators() async {
        let resolved = await withTaskGroup {
            let audiobook = await audiobook
            
            for narrator in audiobook.narrators {
                $0.addTask { () -> (String, [Audiobook])? in
                    do {
                        var audiobooks = try await ABSClient[audiobook.id.connectionID].audiobooks(from: audiobook.id.libraryID, narratorName: narrator, page: 0, limit: 200)
                        
                        audiobooks = audiobooks.filter { $0 != audiobook }
                        
                        guard !audiobooks.isEmpty else {
                            return nil
                        }
                        
                        return (narrator, audiobooks)
                    } catch {
                        return nil
                    }
                }
            }
            
            return await $0.reduce(into: [String: [Audiobook]]()) {
                guard let (narrator, audiobooks) = $1 else {
                    return
                }
                
                $0[narrator] = audiobooks
            }.sorted(by: { $0.0 < $1.0 })
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
    
    nonisolated func loadBookmarks() async {
        guard let bookmarks = try? await PersistenceManager.shared.bookmark[audiobook.id] else {
            await MainActor.run {
                notifyError.toggle()
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.bookmarks = bookmarks
        }
    }
}
