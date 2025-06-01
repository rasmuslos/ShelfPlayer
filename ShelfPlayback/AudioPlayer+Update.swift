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
import ShelfPlayerKit

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
        
        RFNotification[.playbackItemChanged].dispatch(payload: (itemID, chapters, time))
        
        widgetManager.update(itemID: itemID)
    }
    func playStateDidChange(endpointID: UUID, isPlaying: Bool, updateSessionActivation: Bool) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        if updateSessionActivation {
            do {
                try audioSession.setActive(isPlaying)
            } catch {
                logger.error("Failed to set audio session category: \(error)")
            }
        }
        
        RFNotification[.playStateChanged].dispatch(payload: isPlaying)
        
        Task {
            await widgetManager.update(isPlaying: isPlaying)
        }
    }
    
    func bufferHealthDidChange(endpointID: UUID, isBuffering: Bool) {
        guard current?.id == endpointID else {
            return
        }
        
        Task {
            await RFNotification[.bufferHealthChanged].send(payload: isBusy)
        }
        
        Task {
            await widgetManager.update(isBuffering: isBusy)
        }
    }
    
    func durationsDidChange(endpointID: UUID, itemDuration: TimeInterval?, chapterDuration: TimeInterval?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.durationsChanged].send(payload: (itemDuration, chapterDuration))
        }
        
        Task {
            await widgetManager.update(chapterDuration: chapterDuration)
        }
    }
    func currentTimesDidChange(endpointID: UUID, itemCurrentTime: TimeInterval?, chapterCurrentTime: TimeInterval?) {
        guard current?.id == endpointID else {
            return
        }
        
        Task {
            await RFNotification[.currentTimesChanged].send(payload: (itemCurrentTime, chapterCurrentTime))
        }
        
        Task {
            await widgetManager.update(chapterCurrentTime: chapterCurrentTime)
        }
    }
    
    func chapterDidChange(endpointID: UUID, chapter: Chapter?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.chapterChanged].send(payload: chapter)
        }
        
        Task {
            await widgetManager.update(chapter: chapter)
        }
    }
    
    func volumeDidChange(endpointID: UUID, volume: Percentage) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.volumeChanged].send(payload: volume)
        }
    }
    func playbackRateDidChange(endpointID: UUID, playbackRate: Percentage) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.playbackRateChanged].send(payload: playbackRate)
        }
    }
    
    func routeDidChange(endpointID: UUID, route: AudioRoute) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.routeChanged].send(payload: route)
        }
    }
    func sleepTimerDidChange(endpointID: UUID, configuration: SleepTimerConfiguration?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.sleepTimerChanged].send(payload: configuration)
        }
    }
    func sleepTimerDidExpire(endpointID: UUID, configuration: SleepTimerConfiguration) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.sleepTimerExpired].send(payload:  configuration)
        }
    }
    
    func queueDidChange(endpointID: UUID, queue: [ItemIdentifier]) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.queueChanged].send(payload: queue)
        }
    }
    func upNextQueueDidChange(endpointID: UUID, upNextQueue: [ItemIdentifier]) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        Task {
            await RFNotification[.upNextQueueChanged].send(payload: upNextQueue)
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
        await RFNotification[.bufferHealthChanged].send(payload: isBusy)
    }
}

public extension RFNotification.IsolatedNotification {
    static var routeChanged: IsolatedNotification<AudioRoute> { .init("io.rfk.shelfPlayerKit.routeChanged") }
    static var sleepTimerChanged: IsolatedNotification<SleepTimerConfiguration?> { .init("io.rfk.shelfPlayerKit.sleepTimerChanged") }
    static var sleepTimerExpired: IsolatedNotification<SleepTimerConfiguration> { .init("io.rfk.shelfPlayerKit.sleepTimerExpired") }
}
