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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.podcastName = try container.decode(String.self, forKey: .podcastName)
        self.type = try container.decode(EpisodeType.self, forKey: .type)
        self.index = try container.decode(EpisodeIndex.self, forKey: .index)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(podcastName, forKey: .podcastName)
        try container.encode(type, forKey: .type)
        try container.encode(index, forKey: .index)
    }
    
    enum CodingKeys: String, CodingKey {
        case podcastName
        case type
        case index
    }
    
    public struct EpisodeIndex {
        public let season: String?
        public let episode: String
        
        public init(season: String?, episode: String) {
            self.season = season
            self.episode = episode
        }
    }
    public enum EpisodeType: CaseIterable, Sendable {
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
extension Episode.EpisodeType: Identifiable {
    public var id: String {
        switch self {
            case .regular: "regular"
            case .trailer: "trailer"
            case .bonus: "bonus"
        }
    }
}

public extension Episode {
    var podcastID: ItemIdentifier {
        .init(primaryID: id.groupingID!,
              groupingID: nil,
              libraryID: id.libraryID,
              connectionID: id.connectionID,
              type: .podcast)
    }
    
    var links: [URL] {
        get throws {
            guard let description else {
                return []
            }
            
            let document = try SwiftSoup.parse(description)
            
            return try document.select("a")
                .compactMap {
                    guard let href = try? $0.attr("href") else {
                        return nil
                    }
                    
                    return URL(string: href)
                }
            
        }
    }
    
//    var chapterMatches: [(NSRange, TimeInterval)]? {
//        guard let description else {
//            return nil
//        }
//        
//        return description.matches(of: /#"^\s*\(?\b(?:\d{1,2}:)?\d{2}:\d{2}:?\b\)?\s*(.*)$"#/.anchorsMatchLineEndings()).compactMap { match -> (NSRange, TimeInterval)? in
//            guard let timestamp = parseChapterTimestamp(String(match.output.0)), let url = URL(string: "shelfPlayer://chapter?time=\(timestamp)") else {
//                return nil
//            }
//            
//            let lowerBound = description.index(description.startIndex, offsetBy: match.range.lowerBound)
//            let upperBound = description.index(description.startIndex, offsetBy: match.range.upperBound)
//            
////            return (NSRange(location: match.range.lowerBound, length: description.distance(from: description.startIndex, to: match.range) - match.range.lowerBound), timestamp)
//        }
//    }
//    var chapters: [Chapter]? {
//        guard let matches = chapterMatches else {
//            return nil
//        }
//        
//        return matches.enumerated().compactMap { index, match -> Chapter? in
//            let title = match.0.output.1
//            let endOffset: TimeInterval
//            
//            if index >= matches.count - 1 {
//                endOffset = duration
//            } else {
//                endOffset = matches[index + 1].1
//            }
//            
//            return .init(id: index, startOffset: match.1, endOffset: endOffset, title: String(title))
//        }
//    }
    
    var releaseDate: Date? {
        guard let released = released, let milliseconds = Double(released) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }
}

private func parseChapterTimestamp(_ timestamp: String) -> TimeInterval? {
    let cleaned = timestamp
            .trimmingCharacters(in: CharacterSet(charactersIn: "():"))
        
        let parts = cleaned.split(separator: ":").compactMap { Int($0) }
        
        let hours: Int
        let minutes: Int
        let seconds: Int
        
        switch parts.count {
        case 2: // MM:SS
            hours = 0
            minutes = parts[0]
            seconds = parts[1]
        case 3: // HH:MM:SS
            hours = parts[0]
            minutes = parts[1]
            seconds = parts[2]
        default:
                fatalError("Unimplemented")
        }
        
        return TimeInterval(hours * 3600 + minutes * 60 + seconds)
}
