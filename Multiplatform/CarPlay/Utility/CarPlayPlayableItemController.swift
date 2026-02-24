//
//  CarPlayPlayableItemController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.04.25.
//
import Foundation
@preconcurrency import CarPlay
import ShelfPlayback
final class CarPlayPlayableItemController: CarPlayItemController {
    let item: PlayableItem
    let displayCover: Bool
    let row: CPListItem
    private let customHandler: (() -> Void)?
    init(item: PlayableItem, displayCover: Bool, customHandler: (() -> Void)? = nil) {
        self.item = item
        self.displayCover = displayCover
        self.customHandler = customHandler
        if let audiobook = item as? Audiobook {
            var detail = [[String]]()
            if !audiobook.authors.isEmpty {
                detail.append(audiobook.authors)
            }
            if !audiobook.narrators.isEmpty {
                detail.append(audiobook.narrators)
            }
            row = CPListItem(
                text: audiobook.name,
                detailText: detail.map { $0.formatted(.list(type: .and, width: .short)) }.joined(separator: " • "),
                image: nil
            )
            row.isExplicitContent = audiobook.explicit
        } else if let episode = item as? Episode {
            row = CPListItem(
                text: episode.name,
                detailText: episode.authors.formatted(.list(type: .and, width: .short)),
                image: nil
            )
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
        RFNotification[.playbackItemChanged].subscribe { [weak self] in
            self?.row.isPlaying = self?.itemID == $0.0
        }
        RFNotification[.downloadStatusChanged].subscribe { [weak self] _ in
            self?.refreshDownloadAccessory()
        }
        RFNotification[.reloadImages].subscribe { [weak self] itemID in
            guard let self else {
                return
            }
            if let itemID, self.itemID != itemID {
                return
            }
            self.loadCoverIfNeeded()
        }
    }
    var itemID: ItemIdentifier {
        item.id
    }
}
private extension CarPlayPlayableItemController {
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
        Task {
            row.isPlaying = await AudioPlayer.shared.currentItemID == item.id
            row.playbackProgress = await PersistenceManager.shared.progress[item.id].progress
            self.refreshDownloadAccessory()
        }
    }
    func refreshDownloadAccessory() {
        Task {
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
        Task {
            let image = await item.id.platformImage(size: .regular)
            row.setImage(image)
        }
    }
}
