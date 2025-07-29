//
//  AudiobookshelfClient+Util.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation


public struct BookmarkPayload: Codable, Sendable {
    public let libraryItemId: String
    public let title: String
    public let time: Double
    public let createdAt: Double
}

struct HomeRowPayload: Codable {
    let id: String
    let label: String
    let type: String
    let entities: [ItemPayload]
}

// MARK: Responses

struct AuthorizationResponse: Codable {
    let user: User
    
    struct User: Codable {
        let id: String
        // let token: String
        let username: String
        
        let accessToken: String?
        let refreshToken: String?
        
        let bookmarks: [BookmarkPayload]
        let mediaProgress: [ProgressPayload]
    }
}

public struct StatusResponse: Codable, Sendable {
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

struct LibraryResponse: Codable {
    let filterdata: Filterdata
}
struct Filterdata: Codable {
    let genres: [String]
}

struct SearchResponse: Codable {
    let book: [SearchLibraryItem]?
    let podcast: [SearchLibraryItem]?
    let narrators: [NarratorResponse]?
    let series: [SearchSeries]?
    let authors: [ItemPayload]?
    
    struct SearchLibraryItem: Codable {
        let libraryItem: ItemPayload
    }
    struct SearchSeries: Codable {
        let series: ItemPayload
        let books: [ItemPayload]
    }
}

struct ResultResponse: Codable {
    let total: Int
    let results: [ItemPayload]
}

struct EpisodesResponse: Codable {
    let episodes: [EpisodePayload]
}

struct NarratorResponse: Codable {
    let id: String?
    let name: String
    let numBooks: Int
}
struct NarratorsResponse: Codable {
    let narrators: [NarratorResponse]
}

struct CreateCollectionBooksPayload: Codable {
    let name: String
    let libraryId: String
    let books: [String]?
}
struct CreateCollectionItemsPayload: Codable {
    let name: String
    let libraryId: String
    let items: [CollectionItemPayload]?
}

struct UpdateCollectionBooksPayload: Codable {
    let books: [String]?
}
struct UpdateCollectionItemsPayload: Codable {
    let items: [CollectionItemPayload]?
}
struct CollectionItemPayload: Codable {
    let libraryItemId: String
    let episodeId: String?
}
struct UpdateCollectionPayload: Codable {
    let name: String
    let description: String?
}
