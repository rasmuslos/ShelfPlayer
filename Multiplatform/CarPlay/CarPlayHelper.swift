//
//  CarPlayHelper.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
import CarPlay
import ShelfPlayerKit
import SPPlayback

internal struct CarPlayHelper {
    static func buildAudiobookListItem(_ audiobook: Audiobook) async -> CPListItem {
        let detail: String?
        
        if let narrator = audiobook.narrator, let author = audiobook.author {
            detail = "\(author) • \(narrator)"
        } else if let author = audiobook.author {
            detail = author
        } else if let narrator = audiobook.narrator {
            detail = narrator
        } else {
            detail = nil
        }
        
        return await finalizeListItem(CPListItem(text: audiobook.name, detailText: detail, image: nil), item: audiobook, displayCover: true)
    }
    
    static func buildEpisodeListItem(_ episode: Episode, displayCover: Bool) async -> CPListItem {
        await finalizeListItem(CPListItem(text: episode.name, detailText: episode.author, image: nil), item: episode, displayCover: displayCover)
    }
    
    private static func finalizeListItem(_ listItem: CPListItem, item: PlayableItem, displayCover: Bool) async -> CPListItem {
        listItem.userInfo = [
            "identifier": convertIdentifier(item: item),
        ]
        listItem.handler = { _, completion in
            Task {
                try await AudioPlayer.shared.play(item)
                completion()
            }
        }
        
        if displayCover {
            listItem.setImage(await item.cover?.platformImage)
        }
        
        if OfflineManager.shared.offlineStatus(parentId: item.id) == .downloaded {
            listItem.setAccessoryImage(.init(systemName: "arrow.down.circle.fill"))
        }
        
        listItem.playingIndicatorLocation = .leading
        listItem.isPlaying = AudioPlayer.shared.item == item
        listItem.isExplicitContent = (item as? Audiobook)?.explicit ?? false
        
        listItem.playbackProgress = OfflineManager.shared.progressEntity(item: item).progress
        
        return listItem
    }
}
