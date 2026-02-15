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
final class CollectionViewModel: Sendable {
    private(set) var id = UUID()
    
    private(set) var collection: ItemCollection
    
    private(set) var highlighted: PlayableItem? = Episode.placeholder
    private(set) var notifyError = false
    
    @MainActor
    init(collection: ItemCollection) {
        self.collection = collection
        
        setupObservation()
        updateHighlighted()
    }
}

extension CollectionViewModel {
    var audiobooks: [AudiobookSection]? {
        collection.audiobooks?.map { AudiobookSection.audiobook(audiobook: $0) }
    }
    var episodes: [Episode]? {
        collection.episodes
    }
    
    func createPlaylist() {
        Task {
            guard collection.id.type == .collection else {
                return
            }
            
            do {
                let collectionID = try await ABSClient[collection.id.connectionID].createPlaylistCopy(collectionID: collection.id)
                    
                collectionID.navigateIsolated()
                await RFNotification[.collectionChanged].send(payload: collectionID)
            } catch {
                withAnimation {
                    notifyError.toggle()
                }
            }
        }
    }
    func delete() {
        Task {
            do {
                try await ABSClient[collection.id.connectionID].deleteCollection(collection.id)
                
                await PersistenceManager.shared.remove(itemID: collection.id)
                
                await RFNotification[.collectionChanged].send(payload: collection.id)
                await RFNotification[.collectionDeleted].send(payload: collection.id)
            } catch {
                withAnimation {
                    notifyError.toggle()
                }
            }
        }
    }
    
    func refresh() {
        Task {
            try? await ShelfPlayer.refreshItem(itemID: collection.id)
            updateHighlighted()
        }
    }
}

private extension CollectionViewModel {
    func updateHighlighted() {
        Task {
            if let audiobooks = collection.audiobooks {
                for audiobook in audiobooks {
                    if await audiobook.isIncluded(in: .notFinished) {
                        withAnimation {
                            highlighted = audiobook
                        }
                        
                        break
                    }
                }
            } else if let episodes = episodes {
                for episode in episodes {
                    if await episode.isIncluded(in: .notFinished) {
                        withAnimation {
                            highlighted = episode
                        }
                        
                        break
                    }
                }
            }
            
            if highlighted == Episode.placeholder {
                withAnimation {
                    highlighted = nil
                }
            }
        }
    }
    func setupObservation() {
        RFNotification[.progressEntityUpdated].subscribe { [weak self] connectionID, primaryID, groupingID, _ in
            Task { @MainActor [weak self] in
                guard self?.collection.items.contains(where: { $0.id.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }) == true else {
                    return
                }
                
                self?.updateHighlighted()
            }
        }
        RFNotification[.collectionChanged].subscribe { [weak self] collectionID in
            Task { @MainActor [weak self] in
                guard self?.collection.id == collectionID else {
                    return
                }
                
                guard let collection = try? await self?.collection.id.resolved as? ItemCollection else {
                    return
                }
                
                withAnimation { [weak self] in
                    self?.id = .init()
                    self?.collection = collection
                }
                
                self?.updateHighlighted()
            }
        }
    }
}
