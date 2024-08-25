//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.05.24.
//

import Foundation
import SPFoundation
import SPNetwork
import SPOffline
import SPOfflineExtended

public extension MediaResolver {
    func search(episodeName: String?, author: String?) async throws -> [Episode] {
        guard let episodeName = episodeName else { throw ResolveError.missing }
        
        var result = [Episode]()
        
        if let offlineEpisodes = try? OfflineManager.shared.episodes(query: episodeName) {
            result += offlineEpisodes
        }
        
        // TODO: Do this, this is a pain in the ass and could exceed the 10s limit
        
        result = result.filter {
            if let author = author, let audiobookAuthor = $0.author {
                if !audiobookAuthor.localizedStandardContains(author) {
                    return false
                }
            }
            
            return true
        }
        
        return result
    }
    
    func resolve(episodeId: String) async throws -> PlayableItem {
        let (podcastId, episodeId) = MediaResolver.shared.convertIdentifier(identifier: episodeId)
        
        #if canImport(SPOfflineExtended)
        if let episode = try? OfflineManager.shared.episode(episodeId: episodeId) {
            return episode
        }
        #endif
        
        return try await AudiobookshelfClient.shared.item(itemId: podcastId, episodeId: episodeId).0
    }
}
