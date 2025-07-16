//
//  PersonViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 16.07.25.
//

import Foundation
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class CollectionViewModel {
    let collection: ItemCollection
    
    private(set) var notifyError: Bool
    
    @MainActor
    init(collection: ItemCollection) {
        self.collection = collection
        
        notifyError = false
    }
}

extension CollectionViewModel {
    var audiobooks: [AudiobookSection]? {
        collection.audiobooks?.map { AudiobookSection.audiobook(audiobook: $0) }
    }
    var episodes: [Episode]? {
        collection.episodes
    }
    
    var first: PlayableItem? {
        audiobooks?.first?.audiobook ?? episodes?.first
    }
}
