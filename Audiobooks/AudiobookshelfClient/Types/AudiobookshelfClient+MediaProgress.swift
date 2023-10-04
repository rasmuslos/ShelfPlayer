//
//  AudiobookshelfClient+MediaProgress.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

extension AudiobookshelfClient {
    struct MediaPorgress: Codable {
        let id: String
        let userId: String
        let libraryItemId: String
        let episodeId: String?
        
        let mediaItemId: String
        let mediaItemType: String
        
        let duration: Double
        let progress: Double
        let currentTime: Double
        
        let isFinished: Bool
        let hideFromContinueListening: Bool
        
        let lastUpdate: Int64
        let startedAt: Int64
        let finishedAt: Int64?
    }
}
