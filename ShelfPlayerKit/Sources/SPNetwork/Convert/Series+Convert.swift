//
//  Series+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import SPFoundation

internal extension Series {
    convenience init(payload: ItemPayload, connectionID: ItemIdentifier.ConnectionID) {
        self.init(
            id: .init(primaryID: payload.id, groupingID: nil, libraryID: payload.libraryId!, connectionID: connectionID, type: .series),
            name: payload.name!,
            authors: [],
            description: payload.description,
            addedAt: Date(timeIntervalSince1970: (payload.addedAt ?? 0) / 1000))
    }
    
    convenience init(item: ItemPayload, audiobooks: [ItemPayload], connectionID: ItemIdentifier.ConnectionID) {
        var item = item
        item.books = audiobooks
        
        self.init(payload: item, connectionID: connectionID)
    }
}

public extension Audiobook.SeriesFragment {
    static func parse(seriesName: String) -> [Self] {
        seriesName.split(separator: ", ").map {
            if $0.contains(" #") {
                let parts = $0.split(separator: " #")
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
