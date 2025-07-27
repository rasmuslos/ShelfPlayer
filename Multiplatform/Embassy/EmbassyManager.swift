//
//  WidgetManager.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.05.25.
//

import Foundation
import WidgetKit
import AppIntents
import Intents
import OSLog
import ShelfPlayback

#if canImport(ActivityKit)
@preconcurrency import ActivityKit
#endif

#if canImport(UIKit)
import UIKit
#endif

final class EmbassyManager: Sendable {
    let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "EmbassyManager")
    
    // Mutex and async do not like each other, which is bad if you need to call `await activity.update()`
    @MainActor private var isUpdatingActivity = false
    @MainActor private var activity: Activity<SleepTimerLiveActivityAttributes>?
    
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
        } startGrouping: {
            try await AudioPlayer.shared.startGrouping($0, startWithoutListeningSession: $1)
        } createBookmark: {
            if let note = $0, let itemID = await AudioPlayer.shared.currentItemID, let currentTime = await AudioPlayer.shared.currentTime {
                try await PersistenceManager.shared.bookmark.create(at: UInt64(currentTime), note: note, for: itemID)
            } else {
                try await AudioPlayer.shared.createQuickBookmark()
            }
        } skip: {
            if var interval = $0, let currentTime = await AudioPlayer.shared.currentTime {
                if !$1 {
                    interval *= -1
                }
                
                try await AudioPlayer.shared.seek(to: currentTime + interval, insideChapter: false)
            } else {
                try await AudioPlayer.shared.skip(forwards: $1)
            }
        } setSleepTimer: {
            await AudioPlayer.shared.setSleepTimer($0)
        } extendSleepTimer: {
            await AudioPlayer.shared.extendSleepTimer()
        } setPlaybackRate: {
            await AudioPlayer.shared.setPlaybackRate($0)
        }
    }()
    
    func setupObservers() async {
        Embassy.unsetWidgetIsPlaying()
        AppShortcutProvider.updateAppShortcutParameters()
        
        // MARK: General
        
        Task {
            for await _ in Defaults.updates(.tintColor, initial: false) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        // MARK: Donate Intents
        
        RFNotification[.playbackItemChanged].subscribe {
            let itemID = $0.0
            
            Task {
                // App Intent
                
                switch itemID.type {
                    case .episode:
                        // Episode:
                        try await StartIntent(item: itemID.resolved).donate()
                        
                        // Podcast:
                        guard let podcast = try? await ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(itemID).resolved as? Podcast else {
                            break
                        }
                        
                        try await StartPodcastIntent(podcast: podcast).donate()
                    case .audiobook:
                        guard let audiobook = try? await itemID.resolved as? Audiobook else {
                            break
                        }
                        
                        try await StartAudiobookIntent(audiobook: audiobook).donate()
                    default:
                        break
                }
                
                // SiriKit Intent
                
                if let item = try? await itemID.resolved as? PlayableItem, let intent = try? await PlayMediaIntentHandler.buildPlayMediaIntent(item) {
                    let interaction = INInteraction(intent: intent, response: INPlayMediaIntentResponse(code: .success, userActivity: nil))
                    interaction.groupIdentifier = item.id.description
                    
                    try? await interaction.donate()
                }
            }
        }
          
        RFNotification[.progressEntityUpdated].subscribe { connectionID, primaryID, groupingID, entity in
            Task {
                guard entity?.isFinished == true, let item = try? await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) else {
                    return
                }
                
                let _ = try? await IntentDonationManager.shared.deleteDonations(matching: .entityIdentifier(EntityIdentifier(for: ItemEntity.self, identifier: item.id)))
                let _ = try? await IntentDonationManager.shared.deleteDonations(matching: .entityIdentifier(EntityIdentifier(for: AudiobookEntity.self, identifier: item.id)))
                
                try? await INInteraction.delete(with: item.id.description)
            }
        }
        
        // MARK: Quick Actions
        
        RFNotification[.listenNowItemsChanged].subscribe {
            Task { @MainActor in
                let items = await ShelfPlayerKit.listenNowItems.prefix(4)
                
                var shortcuts = [UIApplicationShortcutItem]()
                
                for item in items {
                    let progres = await PersistenceManager.shared.progress[item.id]
                    let subtitle: String?
                    
                    if let duration = progres.duration {
                        subtitle = (duration - progres.currentTime).formatted(.duration(unitsStyle: .short, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2))
                    } else {
                        subtitle = item.authors.formatted(.list(type: .and))
                    }
                    
                    shortcuts.append(UIApplicationShortcutItem(type: "play", localizedTitle: item.name, localizedSubtitle: subtitle, icon: nil, userInfo: [
                        "itemID": item.id.description as NSString,
                    ]))
                }
                
                UIApplication.shared.shortcutItems = shortcuts
            }
        }
        
        // MARK: Listening Time
        
        RFNotification[.timeSpendListeningChanged].subscribe { minutes in
            Defaults[.listenedTodayWidgetValue] = ListenedTodayPayload(total: minutes, updated: .now)
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenedToday")
        }
        
        Task {
            for await _ in Defaults.updates(.listenTimeTarget, initial: false) {
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
        
        RFNotification[.progressEntityUpdated].subscribe { connectionID, primaryID, groupingID, entity in
            Task {
                guard entity?.isFinished == true else {
                    return
                }
                
                guard let current = Defaults[.playbackInfoWidgetValue], let itemID = current.currentItemID, itemID.primaryID == primaryID && itemID.groupingID == groupingID && itemID.connectionID == connectionID else {
                    return
                }
                
                let isDownloaded: Bool
                let nextUp = await ShelfPlayerKit.listenNowItems.first?.id
                
                if let nextUp, await PersistenceManager.shared.download.status(of: nextUp) == .completed {
                    isDownloaded = true
                } else {
                    isDownloaded = false
                }
                
                await self.updatePlaybackInfo(itemID: nil, isDownloaded: isDownloaded, isPlaying: nil)
            }
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
                
                await self.updatePlaybackInfo(itemID: current.currentItemID, isDownloaded: isDownloaded, isPlaying: current.isPlaying)
            }
        }
        
        // MARK: Listen now
        
        RFNotification[.listenNowItemsChanged].subscribe {
            AppShortcutProvider.updateAppShortcutParameters()
            
            Task {
                let current = Defaults[.playbackInfoWidgetValue]
                Defaults[.playbackInfoWidgetValue] = await .init(currentItemID: current?.currentItemID, isDownloaded: current?.isDownloaded ?? false, isPlaying: current?.isPlaying, listenNowItems: ShelfPlayerKit.listenNowItems)
                
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
            }
        }
        
        // MARK: Live activity (Sleep Timer)
        
        RFNotification[.sleepTimerChanged].subscribe {
            self.updateSleepTimerLiveActivity($0)
        }
        RFNotification[.playStateChanged].subscribe { _ in
            self.updateSleepTimerLiveActivity(nil)
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
            
            await updatePlaybackInfo(itemID: itemID, isDownloaded: isDownloaded, isPlaying: isPlaying)
        }
    }
    func updatePlaybackInfo(itemID: ItemIdentifier?, isDownloaded: Bool, isPlaying: Bool?) async {
        await Defaults[.playbackInfoWidgetValue] = .init(currentItemID: itemID, isDownloaded: isDownloaded, isPlaying: isPlaying, listenNowItems: ShelfPlayerKit.listenNowItems)
        
        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.lastListened")
    }
    
    func updateSleepTimerLiveActivity(_ sleepTimer: SleepTimerConfiguration?) {
        Task {
            let shouldContinue = await MainActor.run {
                if isUpdatingActivity {
                    return false
                }
                
                isUpdatingActivity = true
                return true
            }
            
            guard shouldContinue else {
                return
            }
            
            var sleepTimer = sleepTimer
            
            if sleepTimer == nil {
                sleepTimer = await AudioPlayer.shared.sleepTimer
            }
            
            let deadline: Date?
            let chapters: Int?
            
            switch sleepTimer {
                case .interval(let date, _):
                    deadline = date
                    chapters = nil
                case .chapters(let int, _):
                    deadline = nil
                    chapters = int
                default:
                    deadline = nil
                    chapters = nil
            }
            
            let isPlaying = await AudioPlayer.shared.isPlaying
            
            let state = SleepTimerLiveActivityAttributes.ContentState(deadline: deadline, chapters: chapters, isPlaying: isPlaying)
            let content = ActivityContent(state: state, staleDate: deadline)
            
            if let activity = await activity {
                if sleepTimer != nil {
                    await activity.update(content)
                } else {
                    await activity.end(content, dismissalPolicy: .immediate)
                    
                    await MainActor.run {
                        self.activity = nil
                    }
                }
            } else if sleepTimer != nil {
                let isAuthorized = await withCheckedContinuation { continuation in
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { authorized, _ in
                        continuation.resume(returning: authorized)
                    }
                }
                
                guard isAuthorized else {
                    return
                }
                
                let attributes = SleepTimerLiveActivityAttributes(started: .now)
                
                do {
                    let activity = try Activity.request(attributes: attributes, content: content)
                    
                    await MainActor.run {
                        self.activity = activity
                    }
                    
                    logger.info("Started live activity for sleep timer")
                } catch {
                    logger.error("Failed to request live activity: \(error)")
                }
            }
            
            await MainActor.run {
                self.isUpdatingActivity = false
            }
        }
    }
}
