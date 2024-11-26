//
//  Author+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import SPFoundation

extension Author {
    convenience init(item: ItemPayload) {
        let addedAt = item.addedAt ?? 0
        
        self.init(
            id: .init(primaryID: item.id, groupingID: nil, libraryID: item.libraryId, type: .author),
            name: item.name!,
            description: item.description,
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            bookCount: item.numBooks ?? 0)
    }
}
