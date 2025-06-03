//
//  WidgetManager.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.05.25.
//

import Foundation
import WidgetKit
import AppIntents
import ShelfPlayback

final class EmbassyManager: Sendable {
    private init() {
        Task {
            await setupObservers()
        }
    }
    
    let intentAudioPlayer: IntentAudioPlayer = {
        IntentAudioPlayer() {
            if await AudioPlayer.shared.currentItemID == nil {
                return nil
            }
            
            return await AudioPlayer.shared.isPlaying
        } resolveCurrentItemID: {
            await AudioPlayer.shared.currentItemID
        } setPlaying: {
            if $0 {
                await AudioPlayer.shared.play()
            } else {
                await AudioPlayer.shared.pause()
            }
        } start: {
            try await AudioPlayer.shared.start(.init(itemID: $0, origin: .unknown, startWithoutListeningSession: $1))
        }
    }()
    
    func setupObservers() async {
        Embassy.unsetWidgetIsPlaying()
        ShortcutProvider.updateAppShortcutParameters()
        
        // MARK: General
        
        Task {
            for await _ in Defaults.updates(.tintColor) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        // MARK: Donate Intents
        
        RFNotification[.playbackItemChanged].subscribe {
            var itemID = $0.0
            
            Task {
                switch itemID.type {
                    case .episode:
                        try await IntentDonationManager.shared.donate(intent: StartIntent(item: ItemIdentifier(primaryID: itemID.groupingID!, groupingID: nil, libraryID: itemID.libraryID, connectionID: itemID.connectionID, type: .podcast).resolved))
                    case .audiobook:
                        try await IntentDonationManager.shared.donate(intent: PlayAudiobookIntent(item: itemID.resolved))
                    default:
                        return
                }
            }
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
            self.updateLastListenedWidget()
        }
        RFNotification[.playbackItemChanged].subscribe {
            self.updateLastListenedWidget($0.0)
        }
        RFNotification[.playbackStopped].subscribe { _ in
            Embassy.unsetWidgetIsPlaying()
        }
        
        RFNotification[.progressEntityUpdated].subscribe {
            guard let current = Defaults[.playbackInfoWidgetValue], let itemID = current.currentItemID, itemID.primaryID == $0.primaryID && itemID.groupingID == $0.groupingID && itemID.connectionID == $0.connectionID else {
                return
            }
            
            guard $0.3?.isFinished == true else {
                return
            }
            
            Defaults[.playbackInfoWidgetValue] = .init(currentItemID: nil, isDownloaded: false, isPlaying: nil, listenNowItems: current.listenNowItems)
            
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.lastListened")
        }
        RFNotification[.downloadStatusChanged].subscribe { payload in
            Task {
                guard let current = Defaults[.playbackInfoWidgetValue] else {
                    return
                }
                
                let isDownloaded: Bool
                
                if let (itemID, status) = payload {
                    guard itemID == current.currentItemID else {
                        return
                    }
                    
                    isDownloaded = status == .completed
                } else if let currentItemID = current.currentItemID {
                    isDownloaded = await PersistenceManager.shared.download.status(of: currentItemID) == .completed
                } else {
                    isDownloaded = false
                }
                
                Defaults[.playbackInfoWidgetValue] = .init(currentItemID: current.currentItemID, isDownloaded: isDownloaded, isPlaying: current.isPlaying, listenNowItems: current.listenNowItems)
                
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.lastListened")
            }
        }
        
        // MARK: Listen now
        
        RFNotification[.listenNowItemsChanged].subscribe {
            ShortcutProvider.updateAppShortcutParameters()
            
            Task {
                let current = Defaults[.playbackInfoWidgetValue]
                Defaults[.playbackInfoWidgetValue] = await .init(currentItemID: current?.currentItemID, isDownloaded: current?.isDownloaded ?? false, isPlaying: current?.isPlaying, listenNowItems: ShelfPlayerKit.listenNowItems)
                
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
            }
        }
    }
    
    static let shared = EmbassyManager()
}

private extension EmbassyManager {
    func updateLastListenedWidget(_ provided: ItemIdentifier? = nil) {
        Task {
            guard await AudioPlayer.shared.currentItemID != nil || provided != nil else {
                return
            }
            
            let itemID: ItemIdentifier?
            
            if let provided {
                itemID = provided
            } else if let currentItemID = await AudioPlayer.shared.currentItemID {
                itemID = currentItemID
            } else {
                itemID = Defaults[.playbackResumeInfo]?.itemID
            }
            
            guard let itemID else {
                Defaults[.playbackInfoWidgetValue] = await .init(currentItemID: nil, isDownloaded: false, isPlaying: nil, listenNowItems: ShelfPlayerKit.listenNowItems)
                
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.lastListened")
                
                return
            }
            
            let isDownloaded = await PersistenceManager.shared.download.status(of: itemID) == .completed
            let isPlaying: Bool?
            
            if provided == nil {
                isPlaying = await AudioPlayer.shared.currentItemID == nil ? nil : AudioPlayer.shared.isPlaying
            } else {
                isPlaying = true
            }
            
            Defaults[.playbackInfoWidgetValue] = await .init(currentItemID: itemID, isDownloaded: isDownloaded, isPlaying: isPlaying, listenNowItems: ShelfPlayerKit.listenNowItems)
            
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.lastListened")
        }
    }
}
