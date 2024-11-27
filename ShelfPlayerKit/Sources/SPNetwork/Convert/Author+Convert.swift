//
//  Author+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import SPFoundation

extension Author {
    convenience init(payload: ItemPayload) {
        let addedAt = payload.addedAt ?? 0
        
        self.init(
            id: .init(primaryID: payload.id, groupingID: nil, libraryID: payload.libraryId, type: .author),
            name: payload.name!,
            description: payload.description,
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            bookCount: payload.numBooks ?? 0)
    }
}
