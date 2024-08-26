//
//  AudiobookshelfClient+Util.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SPFoundation

struct AudiobookshelfHomeRow: Codable {
    let id: String
    let label: String
    let type: String
    let entities: [AudiobookshelfItem]
}

// MARK: Responses

struct AuthorizationResponse: Codable {
    let user: User
    
    struct User: Codable {
        let id: String
        let token: String
        let username: String
        
        let bookmarks: [AudiobookshelfClient.Bookmark]
        let mediaProgress: [MediaProgress]
    }
}

public struct StatusResponse: Codable {
    public let isInit: Bool
    public let authMethods: [String]
    public let serverVersion: String
}

struct MeResponse: Codable {
    let id: String
    let username: String
    let type: String
    
    let isActive: Bool
    let isLocked: Bool
}

struct LibrariesResponse: Codable {
    let libraries: [Library]
    
    struct Library: Codable {
        let id: String
        let name: String
        let mediaType: String
        let displayOrder: Int
    }
}

struct SearchResponse: Codable {
    let book: [SearchLibraryItem]?
    let podcast: [SearchLibraryItem]?
    // let narrators: [AudiobookshelfItem]
    let series: [SearchSeries]?
    let authors: [AudiobookshelfItem]?
    
    struct SearchLibraryItem: Codable {
        let libraryItem: AudiobookshelfItem
    }
    struct SearchSeries: Codable {
        let series: AudiobookshelfItem
        let books: [AudiobookshelfItem]
    }
}

struct ResultResponse: Codable {
    let results: [AudiobookshelfItem]
}

struct EpisodesResponse: Codable {
    let episodes: [AudiobookshelfPodcastEpisode]
}

struct AuthorsResponse: Codable {
    let authors: [AudiobookshelfItem]
}

public extension AudiobookshelfClient {
    struct Bookmark: Codable {
        public let libraryItemId: String
        public let title: String
        public let time: Double
        public let createdAt: Double
    }
}
