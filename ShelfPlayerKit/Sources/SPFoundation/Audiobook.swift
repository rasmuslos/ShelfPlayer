//
//  Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

public final class Audiobook: PlayableItem {
    public let narrators: [String]
    public let series: [ReducedSeries]
    
    public let explicit: Bool
    public let abridged: Bool
    
    public init(id: ItemIdentifier, name: String, authors: [String], description: String?, cover: Cover?, genres: [String], addedAt: Date, released: String?, size: Int64, duration: TimeInterval, narrators: [String], series: [ReducedSeries], explicit: Bool, abridged: Bool) {
        self.narrators = narrators
        self.series = series
        
        self.explicit = explicit
        self.abridged = abridged
        
        super.init(id: id, name: name, authors: authors, description: description, cover: cover, genres: genres, addedAt: addedAt, released: released, size: size, duration: duration)
    }
}

public extension Audiobook {
    var seriesName: String? {
        if series.isEmpty {
            return nil
        }
        
        return series.map {
            if let formattedSequence = $0.formattedSequence {
                return "\($0.name) #\(formattedSequence)"
            }
            
            return $0.name
        }.joined(separator: ", ")
    }
}

public extension Audiobook {
    struct ReducedSeries: Identifiable, Codable, Hashable {
        public var id: String?
        
        public let name: String
        public let sequence: Float?
        
        public init(id: String?, name: String, sequence: Float?) {
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
