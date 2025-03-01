//
//  Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

public final class Audiobook: PlayableItem, @unchecked Sendable {
    public let subtitle: String?
    
    public let narrators: [String]
    public let series: [SeriesFragment]
    
    public let explicit: Bool
    public let abridged: Bool
    
    public init(id: ItemIdentifier, name: String, authors: [String], description: String?, genres: [String], addedAt: Date, released: String?, size: Int64?, duration: TimeInterval, subtitle: String?, narrators: [String], series: [SeriesFragment], explicit: Bool, abridged: Bool) {
        self.subtitle = subtitle
        
        self.narrators = narrators
        self.series = series
        
        self.explicit = explicit
        self.abridged = abridged
        
        super.init(id: id, name: name, authors: authors, description: description, genres: genres, addedAt: addedAt, released: released, size: size, duration: duration)
    }
}

public extension Audiobook {
    struct SeriesFragment: Identifiable, Codable, Hashable, Sendable {
        public var id: ItemIdentifier?
        
        public let name: String
        public let sequence: Float?
        
        public init(id: ItemIdentifier?, name: String, sequence: Float?) {
            self.id = id
            self.name = name
            self.sequence = sequence
        }
        
        public var formattedSequence: String? {
            guard let sequence else {
                return nil
            }
            
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            
            return formatter.string(from: NSNumber(value: sequence))
        }
    }
}

public extension Audiobook {
    var seriesName: String? {
        if series.isEmpty {
            nil
        } else {
            series.map {
                if let formattedSequence = $0.formattedSequence {
                    return "\($0.name) #\(formattedSequence)"
                }
                
                return $0.name
            }.formatted(.list(type: .and, width: .short))
        }
    }
}
