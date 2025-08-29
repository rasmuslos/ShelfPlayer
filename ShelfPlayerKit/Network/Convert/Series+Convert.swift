//
//  Series+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

extension Series {
    convenience init(payload: ItemPayload, libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID) {
        let audiobooks = payload.books?.compactMap { Audiobook(payload: $0, libraryID: libraryID, connectionID: connectionID) } ?? []
        
        self.init(
            id: .init(primaryID: payload.id, groupingID: nil, libraryID: libraryID, connectionID: connectionID, type: .series),
            name: payload.name!,
            authors: [],
            description: payload.description,
            addedAt: Date(timeIntervalSince1970: (payload.addedAt ?? 0) / 1000),
            audiobooks: audiobooks)
    }
    
    convenience init(item: ItemPayload, audiobooks: [ItemPayload], libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID) {
        var item = item
        item.books = audiobooks
        
        self.init(payload: item, libraryID: libraryID, connectionID: connectionID)
    }
}

public extension Audiobook.SeriesFragment {
    static func parse(seriesName: String) -> [Self] {
        seriesName.split(separator: ", ").map {
            let parts = $0.split(separator: " #")
            
            if parts.count >= 2 {
                let name = parts[0...parts.count - 2].joined(separator: " #")
                
                if let sequence = Float(parts[parts.count - 1]) {
                    return Audiobook.SeriesFragment(id: nil, name: name, sequence: sequence)
                } else {
                    return Audiobook.SeriesFragment(id: nil, name: name.appending(" #").appending(parts[parts.count - 1]), sequence: nil)
                }
            } else {
                return Audiobook.SeriesFragment(id: nil, name: String($0), sequence: nil)
            }
        }
    }
}
