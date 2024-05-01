//
//  IntentHandler.swift
//  siri
//
//  Created by Rasmus Krämer on 01.05.24.
//

import Intents
import SPBase
import SPExtension

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any? {
        self
    }
    
    func resolveMediaItems(mediaSearch: INMediaSearch) async throws -> [INMediaItem] {
        guard let primaryName = mediaSearch.mediaName ?? mediaSearch.albumName ?? mediaSearch.artistName else {
            throw SearchError.unsupportedMediaType
        }
        
        var results = [Item]()
        
        if mediaSearch.mediaType != .unknown && !(mediaSearch.mediaType == .audioBook || mediaSearch.mediaType == .podcastShow || mediaSearch.mediaType == .podcastEpisode) {
            throw SearchError.unsupportedMediaType
        }
        
        if mediaSearch.mediaType == .audioBook || mediaSearch.mediaType == .unknown {
            if let audiobooks = try? await MediaResolver.shared.search(audiobookName: primaryName, author: mediaSearch.artistName) {
                results += audiobooks
            }
        }
        
        if mediaSearch.mediaType == .podcastShow || mediaSearch.mediaType == .unknown {
            if let podcasts = try? await MediaResolver.shared.search(podcastName: primaryName, author: mediaSearch.artistName) {
                results += podcasts
            }
        }
        if mediaSearch.mediaType == .podcastEpisode || mediaSearch.mediaType == .unknown {
            if let episodes = try? await MediaResolver.shared.search(episodeName: primaryName, author: mediaSearch.artistName) {
                results += episodes
            }
        }
        
        guard !results.isEmpty else {
            throw SearchError.unavailable
        }
        
        results.sort { $0.name.levenshteinDistanceScore(to: primaryName) > $1.name.levenshteinDistanceScore(to: primaryName) }
        
        return MediaResolver.shared.convert(items: results)
    }
    
    enum SearchError: Error {
        case unavailable
        case unsupportedMediaType
    }
}
