//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.05.24.
//

import Foundation
import Intents
import SPBase

extension MediaResolver {
    public func convert(items: [Item]) -> [INMediaItem] {
        items.map(convert)
    }
    public func convert(item: Item) -> INMediaItem {
        INMediaItem(
            identifier: item.id,
            title: item.name,
            type: convertType(item: item),
            artwork: convertImage(cover: item.image),
            artist: item.author)
    }
    
    public func convertIdentifier(item: INMediaItem) -> (String, String) {
        return convertIdentifier(identifier: item.identifier ?? "")
    }
    public func convertIdentifier(identifier: String) -> (String, String) {
        var parts = identifier.split(separator: "::")
        
        if parts.count == 2 {
            let podcastId = String(parts.removeFirst())
            let episodeId = String(parts.removeFirst())
            
            return (podcastId, episodeId)
        }
        
        return ("", "")
    }
    private func convertIdentifier(item: Item) -> String {
        if let episode = item as? Episode {
            return "\(episode.podcastId)::\(episode.id)"
        }
        
        return item.id
    }
    
    private func convertType(item: Item) -> INMediaItemType {
        switch item {
            case is Audiobook:
                return .audioBook
            case is Podcast:
                return .podcastShow
            case is Episode:
                return .podcastEpisode
            default:
                return .unknown
        }
    }
    
    private func convertImage(cover: Item.Image?) -> INImage? {
        guard let cover = cover else { return nil }
        
        if cover.type == .local {
            return INImage(url: cover.url)
        }
        
        if let data = try? Data(contentsOf: cover.url) {
            return INImage(imageData: data)
        }
        
        return nil
    }
}
