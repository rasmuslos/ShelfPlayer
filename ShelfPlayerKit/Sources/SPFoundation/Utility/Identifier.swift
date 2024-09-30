//
//  Identifier.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 29.08.24.
//

public func convertIdentifier(identifier: String) -> (itemID: String, episodeID: String?, libraryID: String?, type: Item.ItemType) {
    let parts = identifier.split(separator: "::")
    
    let type = Item.ItemType.parse(String(parts[0]))!
    var libraryID: String? = String(parts[1])
    
    if libraryID == "_" {
        libraryID = nil
    }
    
    let itemID = String(parts[2])
    
    let episodeID: String?
    
    if parts.count == 4 {
        episodeID = String(parts[3])
    } else {
        episodeID = nil
    }
    
    return (itemID, episodeID, libraryID, type)
}

public func convertIdentifier(itemID: String, episodeID: String?, libraryID: String?, type: Item.ItemType) -> String {
    var identifier = "\(type.id)::\(libraryID ?? "_")::\(itemID)"
    
    if let episodeID {
        identifier += "::\(episodeID)"
    }
    
    return identifier
}
public func convertIdentifier(itemID: String, episodeID: String?) -> String {
    convertIdentifier(itemID: itemID, episodeID: episodeID, libraryID: nil, type: episodeID == nil ? .audiobook : .episode)
}

public func convertIdentifier(item: Item) -> String {
    convertIdentifier(itemID: item.identifiers.itemID, episodeID: item.identifiers.episodeID, libraryID: item.libraryID, type: item.type)
}
