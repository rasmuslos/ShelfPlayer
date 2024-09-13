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
    func search(podcastName: String?, author: String?, runOffline: Bool) async throws -> [Podcast] {
        guard let podcastName = podcastName else { throw ResolveError.missing }
        
        var result = [Podcast]()
        
        if let offlinePodcasts = try? OfflineManager.shared.podcasts(query: podcastName) {
            result += offlinePodcasts
        }
        
        if !runOffline, let libraries = try? await AudiobookshelfClient.shared.libraries().filter({ $0.type == .podcasts }) {
            result += await libraries.parallelMap { (try? await AudiobookshelfClient.shared.items(search: podcastName, libraryId: $0.id).1) ?? [] }.reduce([], +)
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
        if let episodes = try? OfflineManager.shared.episodes(podcastId: podcastId), !episodes.isEmpty {
            return episodes
        }
        #endif
        
        return try await AudiobookshelfClient.shared.episodes(podcastId: podcastId)
    }
}
