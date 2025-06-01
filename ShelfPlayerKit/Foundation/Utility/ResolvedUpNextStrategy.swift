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
    
    case none
}
