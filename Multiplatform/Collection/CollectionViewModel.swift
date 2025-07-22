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
    
    nonisolated func createPlaylist() {
        Task {
            guard await collection.id.type == .collection else {
                return
            }
            
            do {
                let collectionID = try await ABSClient[collection.id.connectionID].createPlaylistCopy(collectionID: collection.id)
                    
                await collectionID.navigateIsolated()
                await RFNotification[.collectionChanged].send(payload: collectionID)
            } catch {
                await MainActor.withAnimation {
                    notifyError.toggle()
                }
            }
        }
    }
    nonisolated func delete() {
        Task {
            do {
                try await ABSClient[collection.id.connectionID].deleteCollection(collection.id)
                
                await PersistenceManager.shared.remove(itemID: collection.id)
                
                await RFNotification[.collectionChanged].send(payload: collection.id)
                await RFNotification[.collectionDeleted].send(payload: collection.id)
            } catch {
                await MainActor.withAnimation {
                    notifyError.toggle()
                }
            }
        }
    }
    
    nonisolated func refresh() {
        Task {
            try? await ShelfPlayer.refreshItem(itemID: collection.id)
            updateHighlighted()
        }
    }
}

private extension CollectionViewModel {
    nonisolated func updateHighlighted() {
        Task {
            if let audiobooks = await collection.audiobooks {
                for audiobook in audiobooks {
                    if await audiobook.isIncluded(in: .notFinished) {
                        await MainActor.withAnimation {
                            highlighted = audiobook
                        }
                        
                        break
                    }
                }
            } else if let episodes = await episodes {
                for episode in episodes {
                    if await episode.isIncluded(in: .notFinished) {
                        await MainActor.withAnimation {
                            highlighted = episode
                        }
                        
                        break
                    }
                }
            }
            
            if await highlighted == Episode.placeholder {
                await MainActor.withAnimation {
                    highlighted = nil
                }
            }
        }
    }
    func setupObservation() {
        RFNotification[.progressEntityUpdated].subscribe { [weak self] connectionID, primaryID, groupingID, _ in
            guard self?.collection.items.contains(where: { $0.id.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }) == true else {
                return
            }
            
            self?.updateHighlighted()
        }
        RFNotification[.collectionChanged].subscribe { [weak self] collectionID in
            guard self?.collection.id == collectionID else {
                return
            }
            
            Task.detached {
                guard let collection = try? await self?.collection.id.resolved as? ItemCollection else {
                    return
                }
                
                await MainActor.withAnimation { [weak self] in
                    self?.id = .init()
                    self?.collection = collection
                }
                
                self?.updateHighlighted()
            }
        }
    }
}
