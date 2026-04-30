//
//  EmbassyManager.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.05.25.
//

import Foundation
import Combine
@preconcurrency import ActivityKit
import WidgetKit
import AppIntents
import Intents
import OSLog
import ShelfPlayback

#if canImport(UIKit)
import UIKit
#endif

final class EmbassyManager: Sendable {
    let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "EmbassyManager")

    private let settings = AppSettings.shared

    // Mutex and async do not like each other, which is bad if you need to call `await activity.update()`
    @MainActor private var isUpdatingActivity = false
    @MainActor private var activity: Activity<SleepTimerLiveActivityAttributes>?
    nonisolated(unsafe) private var observerSubscriptions = Set<AnyCancellable>()

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
            try await AudioPlayer.shared.start(.init(itemID: $0, origin: .unknown))
        } startGrouping: {
            try await AudioPlayer.shared.startGrouping($0)
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

    @MainActor func setupObservers() async {
        // MARK: General

        // Reload widgets when tint color changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { _ in
                WidgetCenter.shared.reloadAllTimelines()
            }
            .store(in: &observerSubscriptions)

        // MARK: Donate Intents

        AudioPlayer.shared.events.playbackItemChanged
            .sink { [weak self] itemID, _, _ in
                Task {
                    do {
                        // App Intent
                        try await StartWidgetConfiguration(item: itemID.resolved).donate()

                        switch itemID.type {
                        case .episode:
                            // Episode:
                            try await StartIntent(item: itemID.resolved).donate()

                            // Podcast:
                            guard let podcast = try? await ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(itemID).resolved as? Podcast else {
                                break
                            }

                            try await StartPodcastIntent(podcast: podcast).donate()
                            try await StartWidgetConfiguration(item: podcast).donate()
                        case .audiobook:
                            guard let audiobook = try? await itemID.resolved as? Audiobook else {
                                break
                            }

                            try await StartAudiobookIntent(audiobook: audiobook).donate()
                        default:
                            break
                        }
                    } catch {
                        self?.logger.warning("Failed to donate intent for \(itemID, privacy: .public): \(error, privacy: .public)")
                    }

                    // SiriKit Intent

                    if let item = try? await itemID.resolved as? PlayableItem, let intent = try? await PlayMediaIntentHandler.buildPlayMediaIntent(item) {
                        let interaction = INInteraction(intent: intent, response: INPlayMediaIntentResponse(code: .success, userActivity: nil))
                        interaction.groupIdentifier = item.id.description

                        do {
                            try await interaction.donate()
                        } catch {
                            self?.logger.warning("Failed to donate INInteraction for \(itemID, privacy: .public): \(error, privacy: .public)")
                        }
                    }
                }
            }
            .store(in: &observerSubscriptions)

        PersistenceManager.shared.progress.events.entityUpdated
            .sink { [weak self] connectionID, primaryID, groupingID, entity in
                Task {
                    guard entity?.isFinished == true, let item = try? await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) else {
                        return
                    }

                    do {
                        try await IntentDonationManager.shared.deleteDonations(matching: .entityIdentifier(EntityIdentifier(for: ItemEntity.self, identifier: item.id)))
                    } catch {
                        self?.logger.warning("Failed to delete ItemEntity donations for \(item.id, privacy: .public): \(error, privacy: .public)")
                    }
                    do {
                        try await IntentDonationManager.shared.deleteDonations(matching: .entityIdentifier(EntityIdentifier(for: AudiobookEntity.self, identifier: item.id)))
                    } catch {
                        self?.logger.warning("Failed to delete AudiobookEntity donations for \(item.id, privacy: .public): \(error, privacy: .public)")
                    }

                    do {
                        try await INInteraction.delete(with: item.id.description)
                    } catch {
                        self?.logger.warning("Failed to delete INInteraction for \(item.id, privacy: .public): \(error, privacy: .public)")
                    }
                }
            }
            .store(in: &observerSubscriptions)

        // MARK: Quick Actions

        PersistenceManager.shared.listenNow.events.itemsChanged
            .sink { _ in
                Task {
                    let items = try await PersistenceManager.shared.listenNow.current.prefix(4)

                    var shortcuts = [UIApplicationShortcutItem]()

                    for item in items {
                        let progress = await PersistenceManager.shared.progress[item.id]
                        let subtitle: String?

                        if let duration = progress.duration {
                            subtitle = (duration - progress.currentTime).formatted(.duration(unitsStyle: .short, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2))
                        } else {
                            subtitle = item.authors.formatted(.list(type: .and))
                        }

                        shortcuts.append(UIApplicationShortcutItem(type: "play", localizedTitle: item.name, localizedSubtitle: subtitle, icon: nil, userInfo: [
                            "itemID": item.id.description as NSString,
                        ]))
                    }

                    let shortcutItems = shortcuts
                    await MainActor.run {
                        UIApplication.shared.shortcutItems = shortcutItems
                    }
                }
            }
            .store(in: &observerSubscriptions)

        // MARK: Listening Time

        ListenedTodayTracker.shared.events.timeSpendListeningChanged
            .sink { [weak self] minutes in
                guard let self else { return }
                self.settings.listenedTodayWidgetValue = ListenedTodayPayload(total: minutes, updated: .now)
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenedToday")
            }
            .store(in: &observerSubscriptions)

        // MARK: Last listened

        AudioPlayer.shared.events.playStateChanged
            .sink { [weak self] _ in
                self?.updateLastListenedWidget()
            }
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.playbackItemChanged
            .sink { [weak self] itemID, _, _ in
                self?.updateLastListenedWidget(itemID)
            }
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.playbackStopped
            .sink { _ in
                Embassy.unsetWidgetIsPlaying()
            }
            .store(in: &observerSubscriptions)

        PersistenceManager.shared.progress.events.entityUpdated
            .sink { [weak self] connectionID, primaryID, groupingID, entity in
                Task {
                    guard entity?.isFinished == true else {
                        return
                    }

                    guard let self else { return }
                    guard let current = self.settings.playbackInfoWidgetValue, let itemID = current.currentItemID, itemID.primaryID == primaryID && itemID.groupingID == groupingID && itemID.connectionID == connectionID else {
                        return
                    }

                    await self.updatePlaybackInfo(itemID: nil, isPlaying: nil)
                }
            }
            .store(in: &observerSubscriptions)
        PersistenceManager.shared.download.events.statusChanged
            .sink { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.start")
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
            }
            .store(in: &observerSubscriptions)

        // MARK: Listen now

        PersistenceManager.shared.listenNow.events.itemsChanged
            .sink { _ in
                AppShortcutProvider.updateAppShortcutParameters()

                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.start")
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
            }
            .store(in: &observerSubscriptions)

        // MARK: Live activity (Sleep Timer)

        AudioPlayer.shared.events.sleepTimerChanged
            .sink { [weak self] sleepTimer in
                self?.updateSleepTimerLiveActivity(sleepTimer)
            }
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.playStateChanged
            .sink { [weak self] _ in
                self?.updateSleepTimerLiveActivity(nil)
            }
            .store(in: &observerSubscriptions)
    }

    func endSleepTimerActivity() async {
        for activity in Activity<SleepTimerLiveActivityAttributes>.activities {
            await activity.end(.init(state: .init(deadline: .now, chapters: nil, isPlaying: false), staleDate: nil), dismissalPolicy: .immediate)
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
                itemID = settings.lastPlayedItemID
            }

            guard let itemID else {
                await updatePlaybackInfo(itemID: nil, isPlaying: nil)

                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.start")
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")

                return
            }

            let isPlaying: Bool?

            if provided == nil {
                isPlaying = await AudioPlayer.shared.currentItemID == nil ? nil : AudioPlayer.shared.isPlaying
            } else {
                isPlaying = true
            }

            await updatePlaybackInfo(itemID: itemID, isPlaying: isPlaying)
        }
    }

    func updatePlaybackInfo(itemID: ItemIdentifier?, isPlaying: Bool?) async {
        settings.playbackInfoWidgetValue = .init(currentItemID: itemID, isPlaying: isPlaying)

        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.start")
        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
    }

    func updateSleepTimerLiveActivity(_ sleepTimer: SleepTimerConfiguration?) {
        Task { @MainActor in
            if isUpdatingActivity {
                return
            }

            isUpdatingActivity = true

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

            if let activity = activity {
                if sleepTimer != nil {
                    await activity.update(content)
                } else {
                    await activity.end(content, dismissalPolicy: .immediate)

                    self.activity = nil
                }
            } else if sleepTimer != nil {
                guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                    logger.error("Live Activities are not enabled — cannot start sleep timer activity")
                    self.isUpdatingActivity = false
                    return
                }

                let attributes = SleepTimerLiveActivityAttributes(started: .now)

                do {
                    let activity = try Activity.request(attributes: attributes, content: content)

                    self.activity = activity

                    logger.info("Started live activity for sleep timer")
                } catch {
                    logger.error("Failed to request live activity: \(error)")
                }
            }

            self.isUpdatingActivity = false
        }
    }
}
