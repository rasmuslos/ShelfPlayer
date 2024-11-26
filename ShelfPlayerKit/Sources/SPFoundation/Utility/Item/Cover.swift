//
//  Cover.swift
//  
//
//  Created by Rasmus Krämer on 25.06.24.
//

import Foundation

public struct Cover: Sendable {
    let strategy: RouteStrategy
    
    init(with identifier: ItemIdentifier) async {
        // TODO: Offline Manager is downloaded
        strategy = .local
    }
    
    enum RouteStrategy {
        case local
        case remote
    }
}
