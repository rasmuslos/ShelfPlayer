//
//  Episode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SwiftSoup

public final class Episode: PlayableItem, @unchecked Sendable {
    public let podcastName: String
    
    public let index: EpisodeIndex
    
    public init(id: ItemIdentifier, name: String, authors: [String], description: String?, addedAt: Date, released: String?, size: Int64, duration: TimeInterval, podcastName: String, index: EpisodeIndex) {
        self.podcastName = podcastName
        self.index = index
        
        super.init(id: id, name: name, authors: authors, description: description, genres: [], addedAt: addedAt, released: released, size: size, duration: duration)
    }
    
    public struct EpisodeIndex {
        public let season: String?
        public let episode: String
        
        public init(season: String?, episode: String) {
            self.season = season
            self.episode = episode
        }
    }
}

extension Episode.EpisodeIndex: Codable {}
extension Episode.EpisodeIndex: Comparable {
    public static func <(lhs: Episode.EpisodeIndex, rhs: Episode.EpisodeIndex) -> Bool {
        if let lhsSeason = lhs.season, let rhsSeason = rhs.season, lhsSeason != rhsSeason {
            lhsSeason.localizedCaseInsensitiveCompare(rhsSeason) == .orderedAscending
        } else if lhs.season != nil && rhs.season == nil {
            true
        } else if lhs.season == nil && rhs.season != nil {
            false
        } else {
            lhs.episode.localizedCaseInsensitiveCompare(rhs.episode) == .orderedAscending
        }
    }
}

public extension Episode {
    var releaseDate: Date? {
        guard let released = released, let milliseconds = Double(released) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }
    
    var descriptionText: String? {
        guard let description = description, let document = try? SwiftSoup.parse(description) else {
            return nil
        }
        
        return try? document.text()
    }
}
