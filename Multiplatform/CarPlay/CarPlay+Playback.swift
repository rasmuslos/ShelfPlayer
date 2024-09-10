//
//  CarPlay+Playback.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import CarPlay
import SPFoundation
import SPOffline
import SPPlayback

internal extension CarPlayDelegate {
    static func startPlayback(item: CPSelectableListItem, completion: () -> Void) {
        Task {
            try await AudioPlayer.shared.play((item.userInfo! as! PlayableItem))
            NotificationCenter.default.post(name: Self.updateContentNotifications, object: nil)
        }
        
        completion()
    }
    
    static func updateSections(_ sections: [CPListSection]) -> [CPListSection] {
        sections.map {
            CPListSection(items: $0.items.map {
                if let item = $0 as? CPListItem {
                    let playableItem = $0.userInfo as! PlayableItem
                    
                    if AudioPlayer.shared.item == playableItem {
                        item.isPlaying = true
                        item.playbackProgress = OfflineManager.shared.progressEntity(item: playableItem).progress
                    } else {
                        item.isPlaying = false
                    }
                    
                    return item
                }
                
                return $0
            }, header: $0.header!, headerSubtitle: $0.headerSubtitle, headerImage: $0.headerImage, headerButton: $0.headerButton, sectionIndexTitle: $0.sectionIndexTitle)
        }
    }
    
    static let updateContentNotifications = NSNotification.Name("io.rfk.shelfplayer.carplay.update")
}
