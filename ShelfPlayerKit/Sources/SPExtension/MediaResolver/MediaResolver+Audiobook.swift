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
    func search(audiobookName: String?, author: String?, runOffline: Bool) async throws -> [Audiobook] {
        guard let audiobookName = audiobookName else {
            throw ResolveError.missing
        }
        
        var result = [Audiobook]()
        
        if let offlineAudiobooks = try? OfflineManager.shared.audiobooks(query: audiobookName) {
            result += offlineAudiobooks
        }
            
        if !runOffline, let libraries = try? await AudiobookshelfClient.shared.libraries().filter({ $0.type == .audiobooks }) {
            result += await libraries.parallelMap { (try? await AudiobookshelfClient.shared.items(search: audiobookName, libraryID: $0.id).0) ?? [] }.reduce([], +)
        }
        
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
    
    func resolve(audiobookId: String) async throws -> PlayableItem {
        #if canImport(SPOfflineExtended)
        if let audiobook = try? OfflineManager.shared.audiobook(audiobookId: audiobookId) {
            return audiobook
        }
        #endif
        
        return try await AudiobookshelfClient.shared.item(itemId: audiobookId, episodeId: nil).0
    }
}
