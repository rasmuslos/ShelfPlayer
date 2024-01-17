//
//  AudiobookshelfClient+MediaProgress.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

extension AudiobookshelfClient {
    public struct MediaProgress: Codable {
        public let id: String
        public let libraryItemId: String
        public let episodeId: String?
        
        public let duration: Double
        public let progress: Double
        public let currentTime: Double
        
        public let hideFromContinueListening: Bool
        
        public let lastUpdate: Int64
        public let startedAt: Int64
    }
}
