//
//  CarPlayHelper.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
@preconcurrency import CarPlay
import ShelfPlayerKit
import SPPlayback

@MainActor
struct CarPlayHelper {
    static func buildAudiobookListItem(_ audiobook: Audiobook) -> CPListItem {
        var detail = [[String]]()
        
        if !audiobook.authors.isEmpty {
            detail.append(audiobook.authors)
        }
        if !audiobook.narrators.isEmpty {
            detail.append(audiobook.narrators)
        }
        
        let detailText = detail.map { $0.formatted(.list(type: .and, width: .short)) }.joined(separator: " • ")
        let row = CPListItem(text: audiobook.name, detailText: detailText, image: nil)
        
        row.isExplicitContent = audiobook.explicit
        
        return finalizeListItem(row, item: audiobook, displayCover: true)
    }
    
    static func buildEpisodeListItem(_ episode: Episode, displayCover: Bool) -> CPListItem {
        finalizeListItem(CPListItem(text: episode.name, detailText: episode.authors.formatted(.list(type: .and, width: .short)), image: nil), item: episode, displayCover: displayCover)
    }
    
    private static func finalizeListItem(_ listItem: CPListItem, item: PlayableItem, displayCover: Bool) -> CPListItem {
        listItem.userInfo = item.id
        
        listItem.handler = { listItem, completion in
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
        
        listItem.playingIndicatorLocation = .leading
        
        if displayCover {
            Task {
                listItem.setImage(await item.id.platformCover(size: .regular))
            }
        }
        
        Task {
            listItem.isPlaying = await AudioPlayer.shared.currentItemID == item.id
            listItem.playbackProgress = await PersistenceManager.shared.progress[item.id].progress
            
            switch await PersistenceManager.shared.download.status(of: item.id) {
            case .completed:
                listItem.setAccessoryImage(.init(systemName: "arrow.down.circle.fill"))
            case .downloading:
                listItem.setAccessoryImage(.init(systemName: "circle.circle.fill"))
            default:
                break
            }
        }
        
        return listItem
    }
}
