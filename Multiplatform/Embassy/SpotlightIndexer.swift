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
        let libraries = await ShelfPlayerKit.libraries.sorted { $0.name < $1.name }
        let grouped = Dictionary(grouping: libraries, by: \.connectionID)
        
        grouped.map {
            $0 + $1.map(\.id).joined(separator: ",")
        }
    }
}
