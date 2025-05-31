//
//  WidgetManager.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.05.25.
//

import Foundation
import WidgetKit
import Defaults
import ShelfPlayerKit
import SPPlayback

struct WidgetManager {
    @MainActor private static var isRegistered = false
    
    static func setupObservers() async {
        let shouldRun = await MainActor.run {
            guard !isRegistered else {
                return false
            }
            
            isRegistered = true
            return true
        }
        
        guard shouldRun else {
            return
        }
        
        // MARK: Listening Time
        
        RFNotification[.timeSpendListeningChanged].subscribe { minutes in
            Defaults[.listenedTodayWidgetValue] = ListenedTodayPayload(total: minutes, updated: .now)
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenedToday")
        }
        
        Task {
            for await _ in Defaults.updates(.listenTimeTarget) {
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenedToday")
            }
        }
        
        // MARK: Last listened
        
        RFNotification[.playStateChanged].subscribe { _ in
            updateLastListenedWidget()
        }
        RFNotification[.playbackItemChanged].subscribe {
            updateLastListenedWidget($0.0)
        }
        RFNotification[.playStateChanged].subscribe { _ in
            updateLastListenedWidget()
        }
        
        RFNotification[.progressEntityUpdated].subscribe {
            let itemID = Defaults[.lastListened]?.item?.id
            
            guard itemID?.primaryID == $0.primaryID && itemID?.groupingID == $0.groupingID && itemID?.connectionID == $0.connectionID else {
                return
            }
            
            guard $0.3?.isFinished == true else {
                return
            }
            
            Defaults[.lastListened] = nil
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.lastListened")
        }
    }
}

private extension WidgetManager {
    static func updateLastListenedWidget(_ itemID: ItemIdentifier? = nil) {
        Task {
            let item: PlayableItem?
            
            if let provided = try? await itemID?.resolved as? PlayableItem {
                item = provided
            } else if let playing = try? await (AudioPlayer.shared.currentItemID)?.resolved as? PlayableItem {
                item = playing
            } else {
                item = Defaults[.lastListened]?.item
            }
            
            guard let item else {
                Defaults[.lastListened] = nil
                return
            }
            
            let isDownloaded = await PersistenceManager.shared.download.status(of: item.id) == .downloading
            let isPlaying = await AudioPlayer.shared.currentItemID == nil ? nil : AudioPlayer.shared.isPlaying
            
            Defaults[.lastListened] = LastListenedPayload(item: item, isDownloaded: isDownloaded, isPlaying: isPlaying)
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.lastListened")
        }
    }
}
