//
//  CarPlayPlayableItemController.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.04.25.
//

import Foundation
import Combine
@preconcurrency import CarPlay
import ShelfPlayback

@MainActor
final class CarPlayPlayableItemController: CarPlayItemController {
    let item: PlayableItem
    let displayCover: Bool
    let row: CPListItem

    private let customHandler: (() -> Void)?
    private var observerSubscriptions = Set<AnyCancellable>()

    init(item: PlayableItem, displayCover: Bool, customHandler: (() -> Void)? = nil) {
        self.item = item
        self.displayCover = displayCover
        self.customHandler = customHandler

        if let audiobook = item as? Audiobook {
            row = Self.makeAudiobookRow(audiobook)
            row.isExplicitContent = audiobook.explicit
        } else if let episode = item as? Episode {
            row = Self.makeEpisodeRow(episode)
        } else {
            fatalError("Unsupported item type: \(type(of: item))")
        }

        row.userInfo = item.id
        row.playingIndicatorLocation = .leading

        row.handler = { [weak self] listItem, completion in
            guard let self else {
                completion()
                return
            }

            Task {
                await self.handleSelection(listItem)
                completion()
            }
        }

        refreshState()
        loadCoverIfNeeded()

        AudioPlayer.shared.events.playbackItemChanged
            .sink { [weak self] _ in
                self?.refreshState()
            }
            .store(in: &observerSubscriptions)
        PersistenceManager.shared.download.events.statusChanged
            .sink { [weak self] _ in
                self?.refreshDownloadAccessory()
            }
            .store(in: &observerSubscriptions)
        AppEventSource.shared.reloadImages
            .sink { [weak self] itemID in
                guard let self else {
                    return
                }
                if let itemID, self.itemID != itemID {
                    return
                }
                self.loadCoverIfNeeded()
            }
            .store(in: &observerSubscriptions)
    }
}

private extension CarPlayPlayableItemController {
    var itemID: ItemIdentifier {
        item.id
    }

    static func makeAudiobookRow(_ audiobook: Audiobook) -> CPListItem {
        var detail = [[String]]()

        if !audiobook.authors.isEmpty {
            detail.append(audiobook.authors)
        }

        if !audiobook.narrators.isEmpty {
            detail.append(audiobook.narrators)
        }

        return CPListItem(
            text: audiobook.name,
            detailText: detail.map { $0.formatted(.list(type: .and, width: .short)) }.joined(separator: " • "),
            image: nil
        )
    }

    static func makeEpisodeRow(_ episode: Episode) -> CPListItem {
        CPListItem(
            text: episode.name,
            detailText: episode.authors.formatted(.list(type: .and, width: .short)),
            image: nil
        )
    }

    func handleSelection(_ listItem: any CPSelectableListItem) async {
        if let customHandler {
            customHandler()
            return
        }

        if await AudioPlayer.shared.currentItemID == item.id {
            if await AudioPlayer.shared.isPlaying {
                await AudioPlayer.shared.pause()
            } else {
                await AudioPlayer.shared.play()
            }
            return
        }

        listItem.isEnabled = false

        do {
            try await AudioPlayer.shared.start(.init(itemID: item.id, origin: .carPlay))
        } catch {
            // Keep the row interactive if playback start fails.
        }

        listItem.isEnabled = true
    }

    func refreshState() {
        Task { @MainActor in
            row.isPlaying = await AudioPlayer.shared.currentItemID == item.id
            row.playbackProgress = await PersistenceManager.shared.progress[item.id].progress
            refreshDownloadAccessory()
        }
    }

    func refreshDownloadAccessory() {
        Task { @MainActor in
            switch await PersistenceManager.shared.download.status(of: item.id) {
            case .completed:
                row.setAccessoryImage(.init(systemName: "arrow.down.circle.fill"))
            case .downloading:
                row.setAccessoryImage(.init(systemName: "circle.circle.fill"))
            default:
                row.setAccessoryImage(nil)
            }
        }
    }

    func loadCoverIfNeeded() {
        guard displayCover else {
            return
        }

        Task { @MainActor in
            let image = await item.id.platformImage(size: .regular)
            row.setImage(image)
        }
    }
}
