//
//  ItemID+URL.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 12.01.25.
//

import Foundation


public extension ItemIdentifier {
    var url: URL {
        get async throws {
            guard let connection = await PersistenceManager.shared.authorization[connectionID] else {
                throw PersistenceError.serverNotFound
            }
            
            let base = connection.host
            
            switch type {
            case .author:
                return base.appending(path: "author").appending(path: primaryID)
            case .series:
                return base.appending(path: "library").appending(path: libraryID).appending(path: "series").appending(path: primaryID)
            default:
                let base = base.appending(path: "item")
                
                if let groupingID {
                    return base.appending(path: groupingID)
                } else {
                    return base.appending(path: primaryID)
                }
            }
        }
    }
}
