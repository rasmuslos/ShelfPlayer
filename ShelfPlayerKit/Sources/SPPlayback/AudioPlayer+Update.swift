//
//  AudioPlayer+Update.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.02.25.
//

import Foundation
import MediaPlayer
import Defaults
import RFNotifications
import SPFoundation
import SPPersistence

extension AudioPlayer {
    func didStartPlaying(endpointID: UUID, itemID: ItemIdentifier, chapters: [Chapter], at time: TimeInterval) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
            try audioSession.setActive(true)
        } catch {
            logger.error("Failed to set audio session category: \(error)")
        }
        
        Task { @MainActor in
            RFNotification[.playbackItemChanged].send((itemID, chapters, time))
        }
        
        widgetManager.update(itemID: itemID)
    }
    func playStateDidChange(endpointID: UUID, isPlaying: Bool) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        do {
            try audioSession.setActive(false)
        } catch {
            logger.error("Failed to deactivate audio session: \(error)")
        }
        
        Task { @MainActor in
            RFNotification[.playStateChanged].send(isPlaying)
        }
        
        Task {
            await widgetManager.update(isPlaying: isPlaying)
        }
    }
    
    func bufferHealthDidChange(endpointID: UUID, isBuffering: Bool) {
        guard current?.id == endpointID else {
            return
        }
        
        Task { @MainActor in
            await RFNotification[.bufferHealthChanged].send(isBusy)
        }
        
        Task {
            await widgetManager.update(isBuffering: isBusy)
        }
    }
    
    func durationsDidChange(endpointID: UUID, itemDuration: TimeInterval?, chapterDuration: TimeInterval?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.durationsChanged].send((itemDuration, chapterDuration))
        }
        
        Task {
            await widgetManager.update(chapterDuration: chapterDuration)
        }
    }
    func currentTimesDidChange(endpointID: UUID, itemCurrentTime: TimeInterval?, chapterCurrentTime: TimeInterval?) {
        guard current?.id == endpointID else {
            return
        }
        
        Task { @MainActor in
            RFNotification[.currentTimesChanged].send((itemCurrentTime, chapterCurrentTime))
        }
        
        Task {
            await widgetManager.update(chapterCurrentTime: chapterCurrentTime)
        }
    }
    
    func chapterDidChange(endpointID: UUID, chapter: Chapter?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.chapterChanged].send(chapter)
        }
        
        Task {
            await widgetManager.update(chapter: chapter)
        }
    }
    
    func volumeDidChange(endpointID: UUID, volume: Percentage) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.volumeChanged].send(volume)
        }
    }
    func playbackRateDidChange(endpointID: UUID, playbackRate: Percentage) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.playbackRateChanged].send(playbackRate)
        }
    }
    
    func routeDidChange(endpointID: UUID, route: AudioRoute) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.routeChanged].send(route)
        }
    }
    func sleepTimerDidChange(endpointID: UUID, configuration: SleepTimerConfiguration?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.sleepTimerChanged].send(configuration)
        }
    }
    func sleepTimerDidExpire(endpointID: UUID, configuration: SleepTimerConfiguration) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.sleepTimerExpired].send(configuration)
        }
    }
    
    func queueDidChange(endpointID: UUID, queue: [ItemIdentifier]) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.queueChanged].send(queue)
        }
    }
    func upNextQueueDidChange(endpointID: UUID, upNextQueue: [ItemIdentifier]) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task { @MainActor in
            RFNotification[.upNextQueueChanged].send(upNextQueue)
        }
    }
    
    func didStopPlaying(endpointID: UUID, itemID: ItemIdentifier) async {
        guard current?.id == endpointID else {
            return
        }
        
        do {
            try audioSession.setActive(false)
        } catch {
            logger.error("Failed to deactivate audio session: \(error)")
        }
        
        await widgetManager.invalidate()
        
        await MainActor.run {
            RFNotification[.playbackStopped].send()
        }
        
        Task {
            do {
                try await PersistenceManager.shared.session.attemptSync(early: true)
            } catch {
                logger.error("Failed to sync sessions: \(error)")
            }
        }
    }
    
    func isBusyDidChange() async {
        await RFNotification[.bufferHealthChanged].send(isBusy)
    }
}

public extension RFNotification.Notification {
    static var playbackItemChanged: Notification<(ItemIdentifier, [Chapter], TimeInterval)> {
        .init("io.rfk.shelfPlayerKit.playbackItemChanged")
    }
    static var playStateChanged: Notification<(Bool)> {
        .init("io.rfk.shelfPlayerKit.playStateChanged")
    }
    
    static var skipped: Notification<(Bool)> {
        .init("io.rfk.shelfPlayerKit.skipped")
    }
    
    static var bufferHealthChanged: Notification<(Bool)> {
        .init("io.rfk.shelfPlayerKit.bufferHealthChanged")
    }
    
    static var durationsChanged: Notification<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?)> {
        .init("io.rfk.shelfPlayerKit.durationsChanged")
    }
    static var currentTimesChanged: Notification<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?)> {
        .init("io.rfk.shelfPlayerKit.currentTimesChanged")
    }
    
    static var chapterChanged: Notification<Chapter?> {
        .init("io.rfk.shelfPlayerKit.chapterChanged")
    }
    
    static var volumeChanged: Notification<Percentage> {
        .init("io.rfk.shelfPlayerKit.volumeChanged")
    }
    static var playbackRateChanged: Notification<Percentage> {
        .init("io.rfk.shelfPlayerKit.playbackRateChanged")
    }
    
    static var routeChanged: Notification<AudioRoute> {
        .init("io.rfk.shelfPlayerKit.routeChanged")
    }
    static var sleepTimerChanged: Notification<SleepTimerConfiguration?> {
        .init("io.rfk.shelfPlayerKit.sleepTimerChanged")
    }
    static var sleepTimerExpired: Notification<SleepTimerConfiguration> {
        .init("io.rfk.shelfPlayerKit.sleepTimerExpired")
    }
    
    static var queueChanged: Notification<[ItemIdentifier]> {
        .init("io.rfk.shelfPlayerKit.queueChanged")
    }
    static var upNextQueueChanged: Notification<[ItemIdentifier]> {
        .init("io.rfk.shelfPlayerKit.upNextQueueChanged")
    }
    
    static var playbackStopped: Notification<RFNotificationEmptyPayload> {
        .init("io.rfk.shelfPlayerKit.playbackStopped")
    }
}
