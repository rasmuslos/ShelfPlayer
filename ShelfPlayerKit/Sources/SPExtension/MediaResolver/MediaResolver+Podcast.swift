//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.05.24.
//

import Foundation
import SPBase
import SPOffline
import SPOfflineExtended

public extension MediaResolver {
    func search(podcastName: String?, author: String?) async throws -> [Podcast] {
        guard let podcastName = podcastName else { throw ResolveError.missing }
        
        var result = [Podcast]()
        
        if let offlinePodcasts = try? await OfflineManager.shared.getPodcasts(query: podcastName) {
            result += offlinePodcasts
        }
        
        if !UserDefaults.standard.bool(forKey: "siriOfflineMode"), let libraries = try? await AudiobookshelfClient.shared.getLibraries().filter({ $0.type == .podcasts }) {
            let fetched = await libraries.parallelMap {
                let podcasts = try? await AudiobookshelfClient.shared.getPodcasts(libraryId: $0.id)
                return podcasts ?? []
            }
            
            for podcasts in fetched {
                result += podcasts.filter { !result.contains($0) }
            }
        }
        
        result = result.filter {
            if let author = author, let podcastAuthor = $0.author {
                if !podcastAuthor.localizedStandardContains(author) {
                    return false
                }
            }
            
            return true
        }
        
        return result
    }
    
    func resolve(podcastId: String) async throws -> [PlayableItem] {
        #if canImport(SPOfflineExtended)
        if let episodes = try? await OfflineManager.shared.getEpisodes(podcastId: podcastId), !episodes.isEmpty {
            return episodes
        }
        #endif
        
        return try await AudiobookshelfClient.shared.getEpisodes(podcastId: podcastId)
    }
}
