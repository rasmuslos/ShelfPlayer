//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.05.24.
//

import Foundation
import Intents
import SPFoundation

extension MediaResolver {
    public func convert(items: [Item]) -> [INMediaItem] {
        items.map(convert)
    }
    public func convert(item: Item) -> INMediaItem {
        INMediaItem(
            identifier: item.id,
            title: item.name,
            type: convertType(item: item),
            artwork: convertImage(cover: item.cover),
            artist: item.author)
    }
    
    public func convertItemIdentifier(item: INMediaItem) -> (String, String) {
        return convertIdentifier(identifier: item.identifier ?? "")
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
    
    private func convertImage(cover: Cover?) -> INImage? {
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
