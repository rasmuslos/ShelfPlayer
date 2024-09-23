//
//  ListeningSession.swift
//
//
//  Created by Rasmus Krämer on 02.07.24.
//

#if os(iOS)
import UIKit
#endif

public struct ListeningSession: Identifiable, Codable {
    public let id: String
    public let userId: String
    public let libraryID: String?
    
    public let libraryItemId: String
    public let episodeId: String?
    public let mediaType: String?
    
    let mediaMetadata: AudiobookshelfItemMetadata?
    let chapters: [AudiobookshelfChapter]?
    
    public let displayTitle: String?
    public let displayAuthor: String?
    
    public let coverPath: String?
    
    public let duration: Double?
    public let playMethod: Int
    
    public let mediaPlayer: String
    public let deviceInfo: DeviceInfo
    
    public let serverVersion: String
    
    public let timeListening: Double?
    public let startTime: Double
    public let currentTime: Double
    
    public let startedAt: Double
    public let updatedAt: Double
}

public extension ListeningSession {
    var startDate: Date {
        Date(timeIntervalSince1970: startedAt / 1000)
    }
    var endDate: Date {
        Date(timeIntervalSince1970: updatedAt / 1000)
    }
}

extension ListeningSession {
    public struct DeviceInfo: Codable {
        public let id: String?
        public let deviceId: String?
        public let osName: String?
        public let osVersion: String?
        public let deviceType: String?
        public let manufacturer: String?
        public let clientName: String?
        public let clientVersion: String?
        
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

internal struct ListeningSessionsResponse: Codable {
    let total: Int
    let numPages: Int
    let page: Int
    let itemsPerPage: Int
    
    let sessions: [ListeningSession]
}
