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

struct HomeRowPayload: Codable, Sendable {
    let id: String
    let label: String
    let type: String
    let entities: [ItemPayload]
}

// MARK: Responses

struct AuthorizationResponse: Codable, Sendable {
    let user: User
    
    struct User: Codable, Sendable {
        let id: String
        let username: String
        
        // 2.26+
        let accessToken: String?
        let refreshToken: String?
        // Legacy
        let token: String?
        
        let bookmarks: [BookmarkPayload]
        let mediaProgress: [ProgressPayload]
    }
    
    var versionSafeAccessToken: String {
        get throws {
            guard let token = user.accessToken ?? user.token else {
                throw APIClientError.unauthorized
            }
            
            return token
        }
    }
    var versionSafeRefreshToken: String? {
        user.refreshToken
    }
}

public struct StatusResponse: Codable, Sendable {
    public let isInit: Bool
    public let authMethods: [String]
    public let serverVersion: String
}

struct MeResponse: Codable, Sendable {
    let id: String
    let username: String
    let type: String
    
    let isActive: Bool
    let isLocked: Bool
}

struct LibrariesResponse: Codable, Sendable {
    let libraries: [Library]
    
    struct Library: Codable, Sendable {
        let id: String
        let name: String
        let mediaType: String
        let displayOrder: Int
    }
}

struct LibraryResponse: Codable, Sendable {
    let filterdata: Filterdata
}
struct Filterdata: Codable, Sendable {
    let genres: [String]
}

struct SearchResponse: Codable, Sendable {
    let book: [SearchLibraryItem]?
    let narrators: [NarratorResponse]?
    let series: [SearchSeries]?
    let authors: [ItemPayload]?
    
    let podcast: [SearchLibraryItem]?
    let episodes: [SearchLibraryItem]?
    
    struct SearchLibraryItem: Codable, Sendable {
        let libraryItem: ItemPayload
    }
    struct SearchSeries: Codable, Sendable {
        let series: ItemPayload
        let books: [ItemPayload]
    }
}

struct ResultResponse: Codable, Sendable {
    let total: Int
    let results: [ItemPayload]
}

struct EpisodesResponse: Codable, Sendable {
    let episodes: [EpisodePayload]
}

struct NarratorResponse: Codable, Sendable {
    let id: String?
    let name: String
    let numBooks: Int
}
struct NarratorsResponse: Codable, Sendable {
    let narrators: [NarratorResponse]
}

struct CreateCollectionBooksPayload: Codable, Sendable {
    let name: String
    let libraryId: String
    let books: [String]?
}
struct CreateCollectionItemsPayload: Codable, Sendable {
    let name: String
    let libraryId: String
    let items: [CollectionItemPayload]?
}

struct UpdateCollectionBooksPayload: Codable, Sendable {
    let books: [String]?
}
struct UpdateCollectionItemsPayload: Codable, Sendable {
    let items: [CollectionItemPayload]?
}
struct CollectionItemPayload: Codable, Sendable {
    let libraryItemId: String
    let episodeId: String?
}
struct UpdateCollectionPayload: Codable, Sendable {
    let name: String
    let description: String?
}

