//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 03.04.24.
//

import Foundation
import Defaults

public extension Defaults.Keys {
    static let removeDuplicateSessions = Key("removeDuplicateSessions", default: false)
    
    static let hideFromContinueListening = Key<[HideFromContinueListeningEntity]>("hideFromContinueListening", default: [])
    struct HideFromContinueListeningEntity: Codable, _DefaultsSerializable {
        public let itemId: String
        public let episodeId: String?
    }
}
