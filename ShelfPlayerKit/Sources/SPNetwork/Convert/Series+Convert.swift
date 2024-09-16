//
//  Series+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import SPFoundation

internal extension Series {
    convenience init(item: AudiobookshelfItem) {
        let covers: [Cover] = (item.books ?? item.items ?? []).reduce([], {
            return $0 + [Cover(item: $1)]
        })
        
        self.init(
            id: item.id,
            libraryId: item.libraryId ?? "",
            name: item.name!,
            description: item.description,
            addedAt: Date(timeIntervalSince1970: (item.addedAt ?? 0) / 1000),
            covers: covers)
    }
    
    convenience init(item: AudiobookshelfItem, audiobooks: [AudiobookshelfItem]) {
        var item = item
        item.books = audiobooks
        
        self.init(item: item)
    }
}

public extension Audiobook.ReducedSeries {
    static func parse(seriesName: String) -> [Self] {
        let series = seriesName.split(separator: ", ")
        
        return series.map {
            if $0.contains(" #") {
                let parts = $0.split(separator: " #")
                let name = parts[0...parts.count - 2].joined(separator: " #")
                
                if let sequence = Float(parts[parts.count - 1]) {
                    return Audiobook.ReducedSeries(id: nil, name: name, sequence: sequence)
                } else {
                    return Audiobook.ReducedSeries(id: nil, name: name.appending(" #").appending(parts[parts.count - 1]), sequence: nil)
                }
            } else {
                return Audiobook.ReducedSeries(id: nil, name: String($0), sequence: nil)
            }
        }
    }
}
