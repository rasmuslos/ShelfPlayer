//
//  QueueItem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 21.02.25.
//

import Foundation
import SPFoundation

public struct QueueItem: Sendable {
    public let itemID: ItemIdentifier
    let startWithoutListeningSession: Bool
    
    public init(itemID: ItemIdentifier, startWithoutListeningSession: Bool) {
        self.itemID = itemID
        self.startWithoutListeningSession = startWithoutListeningSession
    }
}
