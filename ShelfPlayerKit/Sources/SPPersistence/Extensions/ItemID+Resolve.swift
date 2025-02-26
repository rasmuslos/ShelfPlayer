//
//  ItemID+Resolve.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.02.25.
//

import Foundation
import SPFoundation

public extension ItemIdentifier {
    var resolved: Item {
        get async throws {
            if let item = await PersistenceManager.shared.download[self] {
                return item
            }
            
            switch type {
            case .audiobook, .episode:
                return try await ABSClient[connectionID].playableItem(itemID: self).0
            case .author:
                return try await ABSClient[connectionID].author(with: self)
            case .series:
                return try await ABSClient[connectionID].series(with: self)
            case .podcast:
                return try await ABSClient[connectionID].podcast(with: self).0
            }
        }
    }
}
