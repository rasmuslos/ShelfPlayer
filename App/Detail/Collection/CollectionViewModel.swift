//
//  CollectionViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 16.07.25.
//

import Foundation
import Combine
import OSLog
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class CollectionViewModel: Sendable {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "CollectionViewModel")

    private var observerSubscriptions = Set<AnyCancellable>()

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
                CollectionEventSource.shared.changed.send(collectionID)
            } catch {
                logger.error("Failed to create playlist copy of \(self.collection.id, privacy: .public): \(error, privacy: .public)")
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

                CollectionEventSource.shared.changed.send(collection.id)
                CollectionEventSource.shared.deleted.send(collection.id)
            } catch {
                logger.error("Failed to delete collection \(self.collection.id, privacy: .public): \(error, privacy: .public)")
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
        PersistenceManager.shared.progress.events.entityUpdated
            .sink { [weak self] connectionID, primaryID, groupingID, _ in
                Task { @MainActor [weak self] in
                    guard let self,
                          self.collection.items.contains(where: { $0.id.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }) else {
                        return
                    }

                    self.updateHighlighted()
                }
            }
            .store(in: &observerSubscriptions)
        CollectionEventSource.shared.changed
            .sink { [weak self] collectionID in
                Task { @MainActor [weak self] in
                    guard let self, self.collection.id == collectionID else {
                        return
                    }

                    guard let collection = try? await self.collection.id.resolved as? ItemCollection else {
                        return
                    }

                    withAnimation {
                        self.id = .init()
                        self.collection = collection
                    }

                    self.updateHighlighted()
                }
            }
            .store(in: &observerSubscriptions)
    }
}
