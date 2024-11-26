//
//  ItemIdentifier+Offline.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import SPFoundation

public extension ItemIdentifier {
    var offlineID: String {
        episodeID ?? primaryID
    }
}
