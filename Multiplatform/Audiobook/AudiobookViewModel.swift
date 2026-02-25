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
        
        RFNotification[.bookmarksChanged].subscribe { [weak self] itemID in
            guard self?.audiobook.id == itemID else {
                return
            }
            
            Task {
                await self?.loadBookmarks()
            }
        }
    }
}

extension AudiobookViewModel {
    func load(refresh: Bool) {
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await self.loadAudiobook() }
                
                $0.addTask { await self.loadAuthors() }
                $0.addTask { await self.loadSeries() }
                $0.addTask { await self.loadNarrators() }
                
                $0.addTask { await self.loadBookmarks() }
                
                if refresh {
                    $0.addTask { await self.sessionLoader.refresh() }
                }
            }
            
            if refresh {
                try? await ShelfPlayer.refreshItem(itemID: self.audiobook.id)
                self.load(refresh: false)
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
    func loadPDF(_ pdf: PlayableItem.SupplementaryPDF) {
        Task {
            let audiobookID = audiobook.id
            
            do {
                let data = try await ABSClient[audiobookID.connectionID].pdf(from: audiobookID, ino: pdf.ino)
                
                withAnimation {
                    notifySuccess.toggle()
                    
                    self.loadingPDF = false
                    self.presentedPDF = data
                }
            } catch {
                withAnimation {
                    loadingPDF = false
                    notifyError.toggle()
                }
            }
        }
    }
    
    func loadAudiobook() async {
        guard let (item, _, chapters, supplementaryPDFs) = try? await ABSClient[audiobook.id.connectionID].playableItem(itemID: audiobook.id) else {
            return
        }
        
        withAnimation {
            self.audiobook = item as! Audiobook
            self.chapters = chapters
            self.supplementaryPDFs = supplementaryPDFs
        }
    }
    
    func loadAuthors() async {
        let resolved = await withTaskGroup {
            let audiobook = audiobook
            
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
            
            var resolved = [String: [Audiobook]]()
            
            for await result in $0 {
                guard let (author, audiobooks) = result else {
                    continue
                }
                
                resolved[author] = audiobooks
            }
            
            return resolved.sorted(by: { $0.0 < $1.0 })
        }
        
        withAnimation {
            self.sameAuthor = resolved
        }
    }
    
    func loadSeries() async {
        let resolved = await withTaskGroup {
            let audiobook = audiobook
            
            for series in audiobook.series {
                $0.addTask { () -> (Audiobook.SeriesFragment, [Audiobook])? in
                    do {
                        let seriesID: ItemIdentifier
                        
                        if let id = series.id {
                            seriesID = id
                        } else {
                            seriesID = try await ABSClient[audiobook.id.connectionID].seriesID(from: self.library.id.libraryID, name: series.name)
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
            
            var resolved = [Audiobook.SeriesFragment: [Audiobook]]()
            
            for await result in $0 {
                guard let (series, audiobooks) = result else {
                    continue
                }
                
                resolved[series] = audiobooks
            }
            
            return resolved.sorted(by: { $0.0.name < $1.0.name })
        }
        
        withAnimation {
            self.sameSeries = resolved
        }
    }
    
    func loadNarrators() async {
        let resolved = await withTaskGroup {
            let audiobook = audiobook
            
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
            
            var resolved = [String: [Audiobook]]()
            
            for await result in $0 {
                guard let (narrator, audiobooks) = result else {
                    continue
                }
                
                resolved[narrator] = audiobooks
            }
            
            return resolved.sorted(by: { $0.0 < $1.0 })
        }
        
        withAnimation {
            self.sameNarrator = resolved
        }
    }
    
    func loadBookmarks() async {
        guard let bookmarks = try? await PersistenceManager.shared.bookmark[audiobook.id] else {
            notifyError.toggle()
            
            return
        }
        
        withAnimation {
            self.bookmarks = bookmarks
        }
    }
}
