//
//  AudiobookViewModel.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import SwiftUI
import SPBase
import SPOfflineExtended

@Observable
class AudiobookViewModel {
    let audiobook: Audiobook
    var libraryId: String!
    
    var navigationBarVisible: Bool
    let offlineTracker: ItemOfflineTracker
    
    var chapters: PlayableItem.Chapters?
    
    var authorId: String?
    
    var audiobooksByAuthor = [Audiobook]()
    var audiobooksInSeries = [Audiobook]()
    
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        
        offlineTracker = audiobook.offlineTracker
        navigationBarVisible = false
    }
}

extension AudiobookViewModel {
    func fetchData(libraryId: String) async {
        self.libraryId = libraryId
        let _ = await (fetchAuthorData(), fetchSeriesData(), fetchAudiobookData())
    }
    
    private func fetchAudiobookData() async {
        if let (_, _, chapters) = try? await AudiobookshelfClient.shared.getItem(itemId: audiobook.id, episodeId: nil) {
            self.chapters = chapters
        }
    }
    
    private func fetchAuthorData() async {
        if let author = audiobook.author, let authorId = try? await AudiobookshelfClient.shared.getAuthorId(name: author, libraryId: libraryId) {
            self.authorId = authorId
            audiobooksByAuthor = (try? await AudiobookshelfClient.shared.getAuthorData(authorId: authorId, libraryId: libraryId).1) ?? []
        }
    }
    
    private func fetchSeriesData() async {
        var seriesId: String?
        
        if let id = audiobook.series.first?.id {
            seriesId = id
        } else if let name = audiobook.series.first?.name {
            seriesId = try? await AudiobookshelfClient.shared.getSeriesId(name: name, libraryId: libraryId)
        }
        
        if let seriesId = seriesId {
            audiobooksInSeries = (try? await AudiobookshelfClient.shared.getAudiobooks(seriesId: seriesId, libraryId: libraryId)) ?? []
        }
    }
}
