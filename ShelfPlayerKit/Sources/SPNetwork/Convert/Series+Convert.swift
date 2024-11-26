//
//  Series+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import SPFoundation

internal extension Series {
    convenience init(item: ItemPayload) {
        let covers: [Cover] = (item.books ?? item.items ?? []).reduce([], {
            print($1)
            return $0 + []
        })
        
        self.init(
            id: .init(primaryID: item.id, groupingID: nil, libraryID: item.libraryId, type: .series),
            name: item.name!,
            authors: [],
            description: item.description,
            addedAt: Date(timeIntervalSince1970: (item.addedAt ?? 0) / 1000),
            covers: covers)
    }
    
    convenience init(item: ItemPayload, audiobooks: [ItemPayload]) {
        var item = item
        item.books = audiobooks
        
        self.init(item: item)
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
