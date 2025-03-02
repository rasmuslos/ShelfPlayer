//
//  AudioPlayer+Update.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.02.25.
//

import Foundation
import MediaPlayer
import RFNotifications
import SPFoundation
import SPPersistence

extension AudioPlayer {
    func didStartPlaying(endpointID: UUID, itemID: ItemIdentifier, at time: TimeInterval) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.playbackItemChanged].send((itemID, time))
        
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
            try audioSession.setActive(true)
        } catch {
            logger.error("Failed to set audio session category: \(error)")
        }
        
        widgetManager.update(itemID: itemID)
    }
    func playStateDidChange(endpointID: UUID, isPlaying: Bool) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.playStateChanged].send(isPlaying)
        
        do {
            try audioSession.setActive(true)
        } catch {
            logger.error("Failed to activate audio session: \(error)")
        }
        
        Task {
            await widgetManager.update(isPlaying: isPlaying)
        }
    }
    
    func bufferHealthDidChange(endpointID: UUID, isBuffering: Bool) {
        guard current?.id == endpointID else {
            return
        }
        
        RFNotification[.bufferHealthChanged].send(isBusy)
        
        Task {
            await widgetManager.update(isBuffering: isBusy)
        }
    }
    
    func durationsDidChange(endpointID: UUID, itemDuration: TimeInterval?, chapterDuration: TimeInterval?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.durationsChanged].send((itemDuration, chapterDuration))
        
        Task {
            await widgetManager.update(chapterDuration: chapterDuration)
        }
    }
    func currentTimesDidChange(endpointID: UUID, itemCurrentTime: TimeInterval?, chapterCurrentTime: TimeInterval?) {
        guard current?.id == endpointID else {
            return
        }
        
        RFNotification[.currentTimesChanged].send((itemCurrentTime, chapterCurrentTime))
        
        Task {
            await widgetManager.update(chapterCurrentTime: chapterCurrentTime)
        }
    }
    
    func chapterDidChange(endpointID: UUID, currentChapterIndex: Int?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.chapterChanged].send(currentChapterIndex)
        
        widgetManager.update(chapterIndex: currentChapterIndex)
    }
    
    func volumeDidChange(endpointID: UUID, volume: Percentage) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.volumeChanged].send(volume)
    }
    func playbackRateDidChange(endpointID: UUID, playbackRate: Percentage) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.playbackRateChanged].send(playbackRate)
    }
    
    func routeDidChange(endpointID: UUID, route: AudioRoute) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.routeChanged].send(route)
    }
    
    func didStopPlaying(endpointID: UUID) async {
        guard current?.id == endpointID else {
            return
        }
        
        await widgetManager.invalidate()
        RFNotification[.playbackStopped].send()
    }
    
    func isBusyDidChange() async {
        RFNotification[.bufferHealthChanged].send(isBusy)
    }
}

public extension RFNotification.Notification {
    static var playbackItemChanged: Notification<(ItemIdentifier, TimeInterval)> {
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
    
    static var chapterChanged: Notification<Int?> {
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
    
    static var playbackStopped: Notification<RFNotificationEmptyPayload> {
        .init("io.rfk.shelfPlayerKit.playbackStopped")
    }
}
