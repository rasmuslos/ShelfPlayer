//
//  LocalSession.swift
//  
//
//  Created by Rasmus Krämer on 02.07.24.
//

#if os(iOS)
import UIKit
#endif

struct LocalSession: Codable {
    let id: String
    let userId: String
    let libraryId: String?
    
    let libraryItemId: String
    let episodeId: String?
    let mediaType: String?
    
    let mediaMetadata: AudiobookshelfItemMetadata?
    let chapters: [AudiobookshelfChapter]?
    
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
}

extension LocalSession {
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
