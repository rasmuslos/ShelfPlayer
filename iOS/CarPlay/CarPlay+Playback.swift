//
//  CarPlay+Playback.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import CarPlay
import SPBase
import SPOffline
import SPPlayback

internal extension CarPlayDelegate {
    static func startPlayback(item: CPSelectableListItem, completion: () -> Void) {
        (item.userInfo! as! PlayableItem).startPlayback()
        NotificationCenter.default.post(name: Self.updateContentNotifications, object: nil)
        
        completion()
    }
    
    static func updateSections(_ sections: [CPListSection]) -> [CPListSection] {
        sections.map {
            CPListSection(items: $0.items.map {
                let item = $0 as! CPListItem
                let playableItem = $0.userInfo as! PlayableItem
                
                if AudioPlayer.shared.item == playableItem {
                    item.isPlaying = true
                    item.playbackProgress = OfflineManager.shared.requireProgressEntity(item: playableItem).progress
                } else {
                    item.isPlaying = false
                }
                
                return item
            }, header: $0.header!, headerSubtitle: $0.headerSubtitle, headerImage: $0.headerImage, headerButton: $0.headerButton, sectionIndexTitle: $0.sectionIndexTitle)
        }
    }
    
    static let updateContentNotifications = NSNotification.Name("io.rfk.shelfplayer.carplay.update")
}
