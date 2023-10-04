//
//  AudiobookshelfClient+Util.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

extension AudiobookshelfClient {
    struct AudiobookshelfHomeRow: Codable {
        let id: String
        let label: String
        let type: String
        let entities: [AudiobookshelfItem]
    }
}
