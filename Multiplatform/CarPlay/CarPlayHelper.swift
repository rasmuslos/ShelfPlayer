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
    static func buildAudiobookListItem(audiobook: Audiobook) async -> CPListItem {
        let detail: String?
        
        if let narrator = audiobook.narrator, let author = audiobook.author {
            detail = "\(narrator) • \(author)"
        } else if let author = audiobook.author {
            detail = author
        } else if let narrator = audiobook.narrator {
            detail = narrator
        } else {
            detail = nil
        }
        
        return await finalizeListItem(CPListItem(text: audiobook.name, detailText: detail, image: nil), item: audiobook)
    }
    
    static func buildEpisodeListItem(episode: Episode) async -> CPListItem {
        await finalizeListItem(CPListItem(text: episode.name, detailText: episode.author, image: nil), item: episode)
    }
    
    private static func finalizeListItem(_ listItem: CPListItem, item: PlayableItem) async -> CPListItem {
        if let data = await item.cover?.data {
            listItem.setImage(UIImage(data: data))
        }
        
        listItem.userInfo = [
            "identifier": convertIdentifier(item: item),
        ]
        listItem.handler = { _, completion in
            Task {
                try await AudioPlayer.shared.play(item)
                completion()
            }
        }
        
        if OfflineManager.shared.offlineStatus(parentId: item.id) == .downloaded {
            listItem.setAccessoryImage(.init(systemName: "arrow.down.circle.fill"))
        }
        
        listItem.playingIndicatorLocation = .trailing
        listItem.isExplicitContent = (item as? Audiobook)?.explicit ?? false
        
        listItem.isPlaying = AudioPlayer.shared.item == item
        listItem.playbackProgress = OfflineManager.shared.progressEntity(item: item).progress
        
        return listItem
    }
}
