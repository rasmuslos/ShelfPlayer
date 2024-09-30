//
//  SpotlightIndexer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.09.24.
//

import Foundation
import CoreSpotlight
import Defaults
import ShelfPlayerKit

internal struct SpotlightIndexer {
    // 3 days
    static let indexWaitTime: TimeInterval = 60 * 60 * 72
    
    static let searchableIndex = CSSearchableIndex(name: "ShelfPlayer_Items", protectionClass: .completeUntilFirstUserAuthentication)
    
    static func index() {
        guard !NetworkMonitor.shared.isRouteLimited else {
            return
        }
        
        let lastIndex = Defaults[.lastSpotlightIndex]
        
        if let lastIndex {
            guard lastIndex.distance(to: .now) > indexWaitTime else {
                return
            }
        }
        
        Task {
            let libraries = try await AudiobookshelfClient.shared.libraries()
            
            for library in libraries {
                
            }
        }
    }
    
    static func indexAudiobookLibrary(_ library: Library) async throws {
        let audiobooks = try await AudiobookshelfClient.shared.audiobooks(libraryID: library.id, sortOrder: .name, ascending: false, limit: nil, page: nil).0
    }
    static func indexPodcastLibrary(_ library: Library) {
        
    }
}
