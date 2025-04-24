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
    
    public let type: EpisodeType
    public let index: EpisodeIndex
    
    public init(id: ItemIdentifier, name: String, authors: [String], description: String?, addedAt: Date, released: String?, size: Int64?, duration: TimeInterval, podcastName: String, type: EpisodeType, index: EpisodeIndex) {
        self.podcastName = podcastName
        self.type = type
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
    public enum EpisodeType {
        case regular
        case trailer
        case bonus
    }
}

extension Episode.EpisodeIndex: Codable {}
extension Episode.EpisodeIndex: Comparable {
    public static func <(lhs: Episode.EpisodeIndex, rhs: Episode.EpisodeIndex) -> Bool {
        if let lhsSeason = lhs.season, let rhsSeason = rhs.season, lhsSeason != rhsSeason {
            lhsSeason.localizedStandardCompare(rhsSeason) == .orderedAscending
        } else if lhs.season != nil && rhs.season == nil {
            true
        } else if lhs.season == nil && rhs.season != nil {
            false
        } else {
            lhs.episode.localizedStandardCompare(rhs.episode) == .orderedAscending
        }
    }
}

extension Episode.EpisodeType: Codable {}

public extension Episode {
    var podcastID: ItemIdentifier {
        .init(primaryID: id.groupingID!,
              groupingID: nil,
              libraryID: id.libraryID,
              connectionID: id.connectionID,
              type: .podcast)
    }
    
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
