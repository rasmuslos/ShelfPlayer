//
//  Identifier.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 29.08.24.
//

public func convertIdentifier(identifier: String) -> (String, String) {
    var parts = identifier.split(separator: "::")
    
    if parts.count == 2 {
        let podcastId = String(parts.removeFirst())
        let episodeId = String(parts.removeFirst())
        
        return (podcastId, episodeId)
    }
    
    return ("", "")
}

public func convertIdentifier(itemID: String, episodeID: String?) -> String {
    if let episodeID {
        return "\(itemID)::\(episodeID)"
    }
    
    return itemID
}
public func convertIdentifier(item: Item) -> String {
    if let episode = item as? Episode {
        return convertIdentifier(itemID: episode.podcastId, episodeID: episode.id)
    }
    
    return convertIdentifier(itemID: item.id, episodeID: nil)
}
