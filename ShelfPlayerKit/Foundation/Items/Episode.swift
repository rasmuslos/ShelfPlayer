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
    
    nonisolated(unsafe) static let chapterRegex = /^\s*\(?(\d{1,2}:(?:\d{2}:)?\d{2})\)?\s*(.*)$/
        .anchorsMatchLineEndings()
    nonisolated(unsafe) static let chapterTimestampRegex = /^\s*\(?(\d{1,2}:(?:\d{2}:)?\d{2})\)?/
        .anchorsMatchLineEndings()
    
    static func parseChapterTimestamp(_ timestamp: String) -> TimeInterval? {
        let parts = timestamp.split(separator: ":").compactMap { Int($0) }
        
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
    
    var chapters: [Chapter]? {
        guard let description, let data = description.data(using: .utf8) else {
            return nil
        }
        
        let attributedString = try? NSAttributedString(data: data, options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ], documentAttributes: nil)
        
        guard let matches = attributedString?.string.matches(of: Self.chapterRegex) else {
            return nil
        }
        
        let durationMapped = matches.compactMap {
            if let timestamp = Self.parseChapterTimestamp(String($0.output.1)) {
                ($0, timestamp)
            } else {
                nil
            }
        }
        
        return durationMapped.enumerated().compactMap { index, element -> Chapter? in
            let (match, timestamp) = element
            let title = String(match.output.2)
            let endOffset: TimeInterval
            
            if index >= matches.count - 1 {
                endOffset = duration
            } else {
                endOffset = durationMapped[index + 1].1
            }
            
            return .init(id: index, startOffset: timestamp, endOffset: endOffset, title: title)
        }
    }
    
    var releaseDate: Date? {
        guard let released = released, let milliseconds = Double(released) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }
}
