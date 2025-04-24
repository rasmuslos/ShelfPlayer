//
//  ShelfPlayerKit.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 06.04.25.
//

import Foundation
import SPFoundation
import SPNetwork

public extension ShelfPlayerKit {
    static var listenNowItems: [PlayableItem] {
        get async {
            await withTaskGroup { group in
                let connectionIDs = await PersistenceManager.shared.authorization.connections.keys
                
                for connectionID in connectionIDs {
                    let hiddenIDs = await PersistenceManager.shared.progress.hiddenFromContinueListening(connectionID: connectionID)
                    
                    group.addTask {
                        do {
                            let libraries = try await ABSClient[connectionID].libraries()
                            
                            return await withTaskGroup(of: [PlayableItem].self, returning: [PlayableItem].self) { childGroup in
                                for library in libraries {
                                    childGroup.addTask {
                                        let items: [PlayableItem]?
                                        
                                        do {
                                            switch library.type {
                                            case .audiobooks:
                                                let rows = try await ABSClient[connectionID].home(for: library.id).0 as [HomeRow<Audiobook>]
                                                items = rows.first { $0.id == "continue-listening" }?.entities
                                            case .podcasts:
                                                let rows = try await ABSClient[connectionID].home(for: library.id).1 as [HomeRow<Episode>]
                                                items = rows.first { $0.id == "continue-listening" }?.entities
                                            }
                                        } catch {
                                            logger.error("Failed to fetch listen now items for library \(library.id) from connection \(connectionID)")
                                            return []
                                        }
                                        
                                        guard let items else {
                                            return []
                                        }
                                        
                                        return items.filter { !hiddenIDs.contains($0.id.primaryID) }
                                    }
                                }
                                
                                return await childGroup.reduce([], +)
                            }
                        } catch {
                            logger.error("Failed to fetch listen now item from connection \(connectionID): \(error)")
                            return []
                        }
                    }
                }
                
                let items = await group.reduce([], +)
                
                let lastPlayed = Dictionary(uniqueKeysWithValues: await withTaskGroup {
                    for item in items {
                        $0.addTask {
                            return (item.id, await PersistenceManager.shared.progress[item.id].lastUpdate)
                        }
                    }
                    
                    return await $0.reduce([]) {
                        $0 + [$1]
                    }
                })
                
                return items.sorted {
                    guard let lhsLastPlayed = lastPlayed[$0.id] else {
                        return false
                    }
                    guard let rhsLastPlayed = lastPlayed[$1.id] else {
                        return true
                    }
                    
                    return lhsLastPlayed > rhsLastPlayed
                }
            }
        }
    }
}

