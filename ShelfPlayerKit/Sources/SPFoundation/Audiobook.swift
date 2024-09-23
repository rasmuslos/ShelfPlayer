//
//  Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

public final class Audiobook: PlayableItem {
    public let narrator: String?
    public let series: [ReducedSeries]
    
    public let explicit: Bool
    public let abridged: Bool
    
    public init(id: String, libraryID: String, name: String, author: String?, description: String?, cover: Cover?, genres: [String], addedAt: Date, released: String?, size: Int64, duration: TimeInterval, narrator: String?, series: [ReducedSeries], explicit: Bool, abridged: Bool) {
        self.narrator = narrator
        self.series = series
        self.explicit = explicit
        self.abridged = abridged
        
        super.init(id: id, libraryID: libraryID, type: .audiobook, name: name, author: author, description: description, cover: cover, genres: genres, addedAt: addedAt, released: released, size: size, duration: duration)
    }
}

public extension Audiobook {
    var seriesName: String? {
        if series.isEmpty {
            return nil
        }
        
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        return series.map {
            if let sequence = $0.sequence, let formatted = formatter.string(from: NSNumber(value: sequence)) {
                return "\($0.name) #\(formatted)"
            }
            
            return $0.name
        }.joined(separator: ", ")
    }
}

public extension Audiobook {
    struct ReducedSeries: Codable {
        public let id: String?
        
        public let name: String
        public let sequence: Float?
        
        public init(id: String?, name: String, sequence: Float?) {
            self.id = id
            self.name = name
            self.sequence = sequence
        }
    }
}
