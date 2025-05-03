//
//  CarPlayPlayableItemController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.04.25.
//

import Foundation
@preconcurrency import CarPlay
import ShelfPlayerKit
import SPPlayback

@MainActor
final class CarPlayPlayableItemController: CarPlayItemController {
    let item: PlayableItem
    let displayCover: Bool
    let row: CPListItem
    
    let customHandler: (() -> Void)?
    
    @MainActor
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
            
            let detailText = detail.map { $0.formatted(.list(type: .and, width: .short)) }.joined(separator: " • ")
            
            row = CPListItem(text: audiobook.name, detailText: detailText, image: nil)
            row.isExplicitContent = audiobook.explicit
        } else if let episode = item as? Episode {
            row = CPListItem(text: episode.name, detailText: episode.authors.formatted(.list(type: .and, width: .short)), image: nil)
        } else {
            fatalError("Unsupported item type: \(type(of: item))")
        }
        
        row.userInfo = item.id
        
        // row.handler = { [weak self] listItem, completion in
        row.handler = { [item] listItem, completion in
            if let customHandler {
                customHandler()
                completion()
                
                return
            }
            
            Task {
                guard await AudioPlayer.shared.currentItemID != item.id else {
                    if await AudioPlayer.shared.isPlaying {
                        await AudioPlayer.shared.pause()
                    } else {
                        await AudioPlayer.shared.play()
                    }
                    
                    completion()
                    return
                }
                
                listItem.isEnabled = false
                try? await AudioPlayer.shared.start(item.id)
                listItem.isEnabled = true
                
                completion()
                return
            }
        }
        
        row.playingIndicatorLocation = .leading
        
        loadCover()
        
        Task {
            row.isPlaying = await AudioPlayer.shared.currentItemID == item.id
            row.playbackProgress = await PersistenceManager.shared.progress[item.id].progress
            
            switch await PersistenceManager.shared.download.status(of: item.id) {
            case .completed:
                row.setAccessoryImage(.init(systemName: "arrow.down.circle.fill"))
            case .downloading:
                row.setAccessoryImage(.init(systemName: "circle.circle.fill"))
            default:
                break
            }
        }
        
        RFNotification[.playbackItemChanged].subscribe { [weak self] in
            self?.row.isPlaying = self?.itemID == $0.0
        }
        RFNotification[.reloadImages].subscribe { [weak self] itemID in
            if let itemID, self?.itemID != itemID {
                return
            }
            
            self?.loadCover()
        }
    }
    
    private nonisolated func loadCover() {
        guard displayCover else {
            return
        }
        
        Task {
            let cover = await item.id.platformCover(size: .regular)
            
            await MainActor.run {
                row.setImage(cover)
            }
        }
    }
    
    var itemID: ItemIdentifier {
        item.id
    }
}
