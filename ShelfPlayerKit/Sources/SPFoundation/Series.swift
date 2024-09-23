//
//  Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

public final class Series: Item {
    public let covers: [Cover]
    
    public init(id: String, libraryID: String, name: String, description: String?, addedAt: Date, covers: [Cover]) {
        self.covers = covers
        
        super.init(id: id, libraryID: libraryID, type: .series, name: name, author: nil, description: description, cover: nil, genres: [], addedAt: addedAt, released: nil)
    }
}
