//
//  ShelfPlayerKit.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 06.04.25.
//

import Foundation


public extension ShelfPlayerKit {
    static var listenNowItems: [PlayableItem] {
        get async {
            await ListenNowCache.shared.current
        }
    }
    static var libraries: [Library] {
        get async {
            await withTaskGroup {
                let connectionIDs = await PersistenceManager.shared.authorization.connections.keys
                
                for connectionID in connectionIDs {
                    $0.addTask {
                        try? await ABSClient[connectionID].libraries()
                    }
                }
                
                return await $0.compactMap { $0 }.reduce([], +)
            }
        }
    }
}
