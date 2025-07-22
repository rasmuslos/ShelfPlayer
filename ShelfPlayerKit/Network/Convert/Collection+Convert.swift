//
//  Collection+Convert.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.07.25.
//

import Foundation

extension ItemCollection {
    convenience init(payload: ItemPayload, type: CollectionType, connectionID: ItemIdentifier.ConnectionID) {
        let items: [Item] = payload.books?.compactMap { Audiobook(payload: $0, libraryID: payload.libraryId!, connectionID: connectionID) } ?? payload.playlistItems?.compactMap {
            if let episode = $0.episode, let podcastName = $0.libraryItem?.media?.metadata.title {
                Episode(episode: episode, podcastName: podcastName, libraryID: payload.libraryId!, fallbackIndex: 0, connectionID: connectionID)
            } else if let libraryItem = $0.libraryItem, let audiobook = Audiobook(payload: libraryItem, libraryID: payload.libraryId!, connectionID: connectionID) {
                audiobook
            } else {
                nil
            }
        } ?? []
        
        self.init(id: .init(primaryID: payload.id, groupingID: nil, libraryID: payload.libraryId!, connectionID: connectionID, type: type.itemType),
                  name: payload.name!,
                  description: payload.description,
                  addedAt: Date(timeIntervalSince1970: (payload.createdAt ?? 0) / 1000),
                  items: items)
    }
}
