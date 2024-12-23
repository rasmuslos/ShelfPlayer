//
//  ListeningSession.swift
//
//
//  Created by Rasmus Krämer on 02.07.24.
//

import Foundation
import SPFoundation

#if os(iOS)
import UIKit
#endif

public struct SessionPayload: Codable {
    public let id: String
    let userId: String
    let libraryID: String?
    
    let libraryItemId: String
    let episodeId: String?
    let mediaType: String?
    
    let mediaMetadata: MetadataPayload?
    let chapters: [ChapterPayload]?
    
    let displayTitle: String?
    let displayAuthor: String?
    
    let coverPath: String?
    
    public let duration: Double?
    public let playMethod: Int
    
    public let mediaPlayer: String
    public let deviceInfo: DeviceInfo
    
    public let serverVersion: String
    public let timeListening: Double?
    
    public let startTime: Double
    public let currentTime: Double?
    
    public let startedAt: Double
    public let updatedAt: Double
}

public extension SessionPayload {
    var startDate: Date {
        Date(timeIntervalSince1970: startedAt / 1000)
    }
    var endDate: Date {
        Date(timeIntervalSince1970: updatedAt / 1000)
    }
}

extension SessionPayload {
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
                id: ShelfPlayerKit.clientID,
                deviceId: ShelfPlayerKit.clientID,
                osName: "iOS",
                osVersion: ShelfPlayerKit.machine,
                deviceType: "iPhone",
                manufacturer: "Apple",
                clientName: "ShelfPlayer",
                clientVersion: ShelfPlayerKit.clientVersion)
        }
    }
}

struct SessionsResponse: Codable {
    let total: Int
    let numPages: Int
    let page: Int
    let itemsPerPage: Int
    
    let sessions: [SessionPayload]
}
