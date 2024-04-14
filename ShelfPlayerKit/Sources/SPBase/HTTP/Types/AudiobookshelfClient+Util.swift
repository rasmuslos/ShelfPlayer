//
//  AudiobookshelfClient+Util.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

#if os(iOS)
import UIKit
#endif

extension AudiobookshelfClient {
    struct AudiobookshelfHomeRow: Codable {
        let id: String
        let label: String
        let type: String
        let entities: [AudiobookshelfItem]
    }
    
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
    
    struct ResultResponse: Codable {
        let results: [AudiobookshelfItem]
    }
    
    struct EpisodesResponse: Codable {
        let episodes: [AudiobookshelfItem.AudiobookshelfPodcastEpisode]
    }
    
    public struct StatusResponse: Codable {
        public let isInit: Bool
        public let authMethods: [String]
        public let serverVersion: String
    }
    
    struct AuthorizationResponse: Codable {
        let user: User
        
        struct User: Codable {
            let id: String
            let token: String
            let username: String
            
            let bookmarks: [Bookmark]
            let mediaProgress: [MediaProgress]
        }
    }
    
    public struct Bookmark: Codable {
        public let libraryItemId: String
        public let title: String
        public let time: Double
        public let createdAt: Double
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
    
    struct AuthorsResponse: Codable {
        let authors: [AudiobookshelfItem]
    }
    
    struct LocalSession: Codable {
        let id: String
        let userId: String
        let libraryId: String?
        
        let libraryItemId: String
        let episodeId: String?
        let mediaType: String?
        
        let mediaMetadata: AudiobookshelfItem.AudiobookshelfItemMetadata?
        let chapters: [AudiobookshelfItem.AudiobookshelfChapter]?
        
        let displayTitle: String?
        let displayAuthor: String?
        
        let coverPath: String?
        
        let duration: Double?
        let playMethod: Int
        
        let mediaPlayer: String
        let deviceInfo: DeviceInfo
        
        let serverVersion: String
        
        let timeListening: Double
        let startTime: Double
        let currentTime: Double
        
        let startedAt: Double
        let updatedAt: Double
        
        struct DeviceInfo: Codable {
            let id: String
            let deviceId: String
            let osName: String
            let osVersion: String?
            let deviceType: String
            let manufacturer: String
            let clientName: String
            let clientVersion: String
            
            static var current: Self {
                .init(
                    id: AudiobookshelfClient.shared.clientId,
                    deviceId: AudiobookshelfClient.shared.clientId,
                    osName: "iOS",
                    osVersion: {
                        #if os(iOS)
                        return UIDevice.current.systemVersion
                        #else
                        return nil
                        #endif
                    }(),
                    deviceType: "iPhone",
                    manufacturer: "Apple",
                    clientName: "ShelfPlayer",
                    clientVersion: AudiobookshelfClient.shared.clientVersion)
            }
        }
    }
    
    struct MeResponse: Codable {
        let id: String
        let username: String
        let type: String
        
        let isActive: Bool
        let isLocked: Bool
    }
}
