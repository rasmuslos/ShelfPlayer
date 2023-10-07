//
//  Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

class Audiobook: Item {
    let narrator: String?
    let series: ReducedSeries
    
    let duration: Double
    
    let explicit: Bool
    let abridged: Bool
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Image?, genres: [String], addedAt: Date, released: String?, size: Int64, narrator: String?, series: ReducedSeries, duration: Double, explicit: Bool, abridged: Bool) {
        self.narrator = narrator
        self.series = series
        self.duration = duration
        self.explicit = explicit
        self.abridged = abridged
        
        super.init(id: id, additionalId: nil, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released, size: size)
    }
    
    struct ReducedSeries {
        let id: String?
        let name: String?
        let audiobookSeriesName: String?
    }
}
