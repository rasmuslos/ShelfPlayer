//
//  SpotlightIndex.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.05.25.
//

import Foundation
import ShelfPlayerKit

struct SpotlightIndexer {
    static func run() async {
        
    }
    
    static func planRun() async throws {
        try await PersistenceManager.shared.authorization.fetchConnections()
    }
}
