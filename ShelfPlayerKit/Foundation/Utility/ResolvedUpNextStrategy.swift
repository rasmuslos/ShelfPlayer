//
//  ResolvedUpNextStrategy.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.05.25.
//

import Foundation

public enum ResolvedUpNextStrategy: Sendable {
    case listenNow
    
    case series(ItemIdentifier)
    case podcast(ItemIdentifier)
    
    case collection(ItemIdentifier)
    
    case none
    
    public var itemID: ItemIdentifier? {
        switch self {
            case .series(let itemID):
                itemID
            case .podcast(let itemID):
                itemID
            case .collection(let itemID):
                itemID
            default:
                nil
        }
    }
}

private enum ResolverError: Error {
    case missing
}
