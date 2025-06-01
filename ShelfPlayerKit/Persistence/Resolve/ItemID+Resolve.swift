//
//  ItemID+Resolve.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.02.25.
//

import Foundation


public extension ItemIdentifier {
    var resolved: Item {
        get async throws {
            try await resolvedComplex.0
        }
    }
    var resolvedComplex: (Item, [Episode]) {
        get async throws {
            try await ResolveCache.shared.resolve(self)
        }
    }
}
