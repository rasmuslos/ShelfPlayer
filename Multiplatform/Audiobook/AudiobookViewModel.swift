//
//  AudiobookViewModel.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SwiftUI
import SPFoundation
import SPOfflineExtended

@Observable
final internal class AudiobookViewModel {
    var audiobook: Audiobook
    
    var libraryId: String!
    
    var navigationBarVisible = false
    
    var chapters: PlayableItem.Chapters?
    
    var authorId: String?
    
    var sameAuthor = [Audiobook]()
    var sameSeries = [Audiobook]()
    var sameNarrator = [Audiobook]()
    
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        libraryId = audiobook.libraryId
    }
}

internal extension AudiobookViewModel {
    func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.loadAudiobook() }
            $0.addTask { await self.loadAuthor() }
            $0.addTask { await self.loadSeries() }
            $0.addTask { await self.loadNarrator() }
            
            await $0.waitForAll()
        }
    }
    
    private func loadAudiobook() async {
        if let (item, _, chapters) = try? await AudiobookshelfClient.shared.getItem(itemId: audiobook.id, episodeId: nil) {
            self.audiobook = item as! Audiobook
            self.chapters = chapters
        }
    }
    
    private func loadAuthor() async {
        guard let author = audiobook.author, let authorId = try? await AudiobookshelfClient.shared.getAuthorId(name: author, libraryId: libraryId) else {
            return
        }
        
        self.authorId = authorId
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.getAuthorData(authorId: authorId, libraryId: libraryId).1 else {
            return
        }
        
        sameAuthor = audiobooks
    }
    
    private func loadSeries() async {
        let seriesId: String
        
        if let id = audiobook.series.first?.id {
            seriesId = id
        } else if let name = audiobook.series.first?.name, let id = try? await AudiobookshelfClient.shared.getSeriesId(name: name, libraryId: libraryId) {
            seriesId = id
        } else {
            return
        }
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.getAudiobooks(seriesId: seriesId, libraryId: libraryId) else {
            return
        }
        
        sameSeries = audiobooks
    }
    
    private func loadNarrator() async {
        guard let narratorName = audiobook.narrator else {
            return
        }
        
        guard let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(narratorName: narratorName, libraryId: libraryId) else {
            return
        }
        
        sameNarrator = audiobooks
    }
}
