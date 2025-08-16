//
//  AudioPlayer+Update.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.02.25.
//

import Foundation
import MediaPlayer
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
    func playStateDidChange(endpointID: UUID, isPlaying: Bool, updateSessionActivation: Bool) async {
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
        
        await widgetManager.update(isPlaying: isPlaying)
    }
    
    func bufferHealthDidChange(endpointID: UUID, isBuffering: Bool) async {
        guard current?.id == endpointID else {
            return
        }
        
        await widgetManager.update(isBuffering: isBusy)
        await RFNotification[.bufferHealthChanged].send(payload: isBusy)
    }
    
    func durationsDidChange(endpointID: UUID, itemDuration: TimeInterval?, chapterDuration: TimeInterval?) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await widgetManager.update(chapterDuration: chapterDuration)
        await RFNotification[.durationsChanged].send(payload: (itemDuration, chapterDuration))
    }
    func currentTimesDidChange(endpointID: UUID, itemCurrentTime: TimeInterval?, chapterCurrentTime: TimeInterval?) async {
        guard current?.id == endpointID else {
            return
        }
        
        await widgetManager.update(chapterCurrentTime: chapterCurrentTime)
        await RFNotification[.currentTimesChanged].send(payload: (itemCurrentTime, chapterCurrentTime))
    }
    
    func chapterDidChange(endpointID: UUID, chapter: Chapter?) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await RFNotification[.chapterChanged].send(payload: chapter)
    }
    func chapterIndexDidChange(endpointID: UUID, chapterIndex: Int?, chapterCount: Int) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await widgetManager.update(chapterIndex: chapterIndex, chapterCount: chapterCount)
    }
    
    func volumeDidChange(endpointID: UUID, volume: Percentage) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await RFNotification[.volumeChanged].send(payload: volume)
    }
    
    func playbackRateDidChange(endpointID: UUID, playbackRate: Percentage) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await widgetManager.update(targetPlaybackRate: playbackRate)
        await RFNotification[.playbackRateChanged].send(payload: playbackRate)
    }
    
    func routeDidChange(endpointID: UUID, route: AudioRoute) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await RFNotification[.routeChanged].send(payload: route)
    }
    func sleepTimerDidChange(endpointID: UUID, configuration: SleepTimerConfiguration?) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await RFNotification[.sleepTimerChanged].send(payload: configuration)
    }
    func sleepTimerDidExpire(endpointID: UUID, configuration: SleepTimerConfiguration) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await RFNotification[.sleepTimerExpired].send(payload:  configuration)
    }
    
    func queueDidChange(endpointID: UUID, queue: [ItemIdentifier]) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await widgetManager.update(queueCount: queue.count)
        await RFNotification[.queueChanged].send(payload: queue)
    }
    func upNextQueueDidChange(endpointID: UUID, upNextQueue: [ItemIdentifier]) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await RFNotification[.upNextQueueChanged].send(payload: upNextQueue)
    }
    func upNextStrategyDidChange(endpointID: UUID, strategy: ResolvedUpNextStrategy?) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        await RFNotification[.upNextStrategyChanged].send(payload: strategy)
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
