//
//  AutomaticAudiobookDownloadManager.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 03.05.25.
//

import Foundation
import SPFoundation

public struct AutomaticDownloadManager: Sendable {
    public func itemDidComplete(itemID: ItemIdentifier) {
        
    }
    
    public static let shared = AutomaticDownloadManager()
}

struct AutomaticAudiobookDownloadCondition {
    let id: String
    let itemID: ItemIdentifier
    
    enum ConditionType {
        case manual
        case episode
        case listenNowItem
    }
}
