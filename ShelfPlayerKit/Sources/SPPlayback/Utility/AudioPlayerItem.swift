//
//  QueueItem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 21.02.25.
//

import Foundation
import SPFoundation

public struct AudioPlayerItem: Sendable {
    public let itemID: ItemIdentifier
    
    let origin: PlaybackOrigin
    let startWithoutListeningSession: Bool
    
    public init(itemID: ItemIdentifier, origin: PlaybackOrigin, startWithoutListeningSession: Bool) {
        self.itemID = itemID
        
        self.origin = origin
        self.startWithoutListeningSession = startWithoutListeningSession
    }
    
    public enum PlaybackOrigin: Sendable {
        case author(ItemIdentifier)
        case narrator(ItemIdentifier)
        case series(ItemIdentifier)
        case audiobook(ItemIdentifier)
        
        case episode(ItemIdentifier)
        case podcast(ItemIdentifier)
        
        case carPlay
        case upNextQueue
        
        case unknown
    }
}
