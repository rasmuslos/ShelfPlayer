//
//  ShelfPlayerKit.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 06.04.25.
//

import Foundation
import CoreSpotlight

public extension ShelfPlayerKit {
    static var listenNowItems: [PlayableItem] {
        get async {
            await PersistenceManager.shared.listenNow.current
        }
    }
    static var libraries: [Library] {
        get async {
            await withTaskGroup {
                for connectionID in await PersistenceManager.shared.authorization.connectionIDs {
                    $0.addTask {
                        try? await ABSClient[connectionID].libraries()
                    }
                }
                
                return await $0.compactMap { $0 }.reduce([], +)
            }
        }
    }
    
    static func globalSearch(query: String, includeOnlineSearchResults: Bool, filter: Bool = false, allowedItemTypes: [ItemIdentifier.ItemType]? = nil) async throws -> [Item] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        var result = await withTaskGroup(of: [Item].self) {
            $0.addTask {
                guard let result = try? await resolveSpotlightItems(query: query) else {
                    return []
                }
                
                return result
            }
            $0.addTask {
                guard let result = try? await resolveDownloadedItems(query: query) else {
                    return []
                }
                
                return result
            }
            
            if includeOnlineSearchResults {
                $0.addTask {
                    guard let result = try? await resolveOnlineItems(query: query) else {
                        return []
                    }
                    
                    return result
                }
            }
            
            return await $0.reduce(into: []) { result, value in
                result.append(contentsOf: value.filter { !result.contains($0) })
            }
        }
        
        if let allowedItemTypes {
            result = result.filter { allowedItemTypes.contains($0.id.type) }
        }
        
        if filter {
            let audiobookFilter = Defaults[.audiobooksFilter]
            
            var filtered = [Item]()
            
            for item in result {
                if let audiobook = item as? Audiobook {
                    if await audiobook.isIncluded(in: audiobookFilter) {
                        filtered.append(audiobook)
                    }
                } else {
                    filtered.append(item)
                }
            }
            
            result = filtered
        }
        
        result.sort { $0.name.levenshteinDistanceScore(to: query) > $1.name.levenshteinDistanceScore(to: query) }
        
        return result
    }
}
 
private extension ShelfPlayerKit {
    static func resolveSpotlightItems(query: String) async throws -> [Item] {
        let query = "title == '*\(query)*'cdw || artist == '*\(query)*'cdw"
        
        let context = CSSearchQueryContext()
        context.fetchAttributes = ["identifier"]
        
        let searchQuery = CSSearchQuery(queryString: query, queryContext: context)
        
        var results = [Item]()
        
        for try await result in searchQuery.results {
            let identifier = result.item.uniqueIdentifier
            
            // This check is technically only required during development but it can't hurt
            
            guard ItemIdentifier.isValid(identifier) else {
                continue
            }
            
            try await results.append(ItemIdentifier(identifier).resolved)
        }
        
        return results
    }
    static func resolveDownloadedItems(query: String) async throws -> [Item] {
        let itemIDs = try await PersistenceManager.shared.download.search(query: query)
        
        return await withTaskGroup {
            for itemID in itemIDs {
                $0.addTask {
                    try? await itemID.resolved
                }
            }
            
            return await $0.reduce(into: []) { result, value in
                guard let value else {
                    return
                }
                
                result.append(value)
            }
        }
    }
    
    static func resolveOnlineItems(query: String) async throws -> [Item] {
        try await PersistenceManager.shared.authorization.waitForConnections()
        
        return await withTaskGroup(of: [Item].self) {
            for connectionID in await PersistenceManager.shared.authorization.connectionIDs {
                $0.addTask {
                    guard let libraries = try? await ABSClient[connectionID].libraries() else {
                        return []
                    }
                    
                    return await withTaskGroup {
                        for library in libraries {
                            $0.addTask {
                                do {
                                    let (audiobooks, authors, narrators, series, podcasts, episodes) = try await ABSClient[connectionID].items(in: library, search: query)
                                    let part = audiobooks + authors + narrators + series
                                    return part + podcasts + episodes
                                } catch {
                                    return []
                                }
                            }
                        }
                        
                        return await $0.reduce(into: []) {
                            $0.append(contentsOf: $1)
                        }
                    }
                }
            }
            
            return await $0.reduce(into: []) {
                $0.append(contentsOf: $1)
            }
        }
    }
}
