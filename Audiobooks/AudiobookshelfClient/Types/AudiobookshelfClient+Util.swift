//
//  AudiobookshelfClient+Util.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

// MARK: Audiobook home row

extension AudiobookshelfClient {
    struct AudiobookshelfHomeRow: Codable {
        let id: String
        let label: String
        let type: String
        let entities: [AudiobookshelfItem]
    }
}

// MARK: Search

extension AudiobookshelfClient {
    struct SearchResponse: Codable {
        let book: [SearchLibraryItem]?
        let podcast: [SearchLibraryItem]?
        // let narrators: [AudiobookshelfItem]
        let series: [SearchSeries]?
        let authors: [AudiobookshelfItem]?
        
        struct SearchLibraryItem: Codable {
            let matchKey: String
            let matchText: String
            let libraryItem: AudiobookshelfItem
        }
        struct SearchSeries: Codable {
            let series: AudiobookshelfItem
            let books: [AudiobookshelfItem]
        }
    }
}

// MARK: Results

extension AudiobookshelfClient {
    struct ResultResponse: Codable {
        let results: [AudiobookshelfItem]
    }
}

// MARK: Episodes response

extension AudiobookshelfClient {
    struct EpisodesResponse: Codable {
        let episodes: [AudiobookshelfItem.AudiobookshelfPodcastEpisode]
    }
}
