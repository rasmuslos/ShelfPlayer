//
//  QueueItem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 21.02.25.
//

import Foundation
import ShelfPlayerKit

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
        case series(ItemIdentifier)
        case podcast(ItemIdentifier)
        
        case collection(ItemIdentifier)
        
        case upNextQueue
        case carPlay
        
        case unknown
    }
}
