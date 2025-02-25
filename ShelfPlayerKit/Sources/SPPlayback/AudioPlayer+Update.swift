//
//  AudioPlayer+Update.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.02.25.
//

import Foundation
import SPFoundation
import RFNotifications

extension AudioPlayer {
    func didStartPlaying(endpointID: UUID, itemID: ItemIdentifier, at time: TimeInterval) async {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.playbackItemChanged].send((itemID, time))
    }
    func playStateDidChange(endpointID: UUID, isPlaying: Bool) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.playStateChanged].send(isPlaying)
    }
    
    func bufferHealthDidChange(endpointID: UUID, isBuffering: Bool) {
        guard current?.id == endpointID else {
            return
        }
        
        RFNotification[.bufferHealthChanged].send(isBuffering)
    }
    
    func durationsDidChange(endpointID: UUID, itemDuration: TimeInterval?, chapterDuration: TimeInterval?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.durationsChanged].send((itemDuration, chapterDuration))
    }
    func currentTimesDidChange(endpointID: UUID, itemCurrentTime: TimeInterval?, chapterCurrentTime: TimeInterval?) {
        guard current?.id == endpointID else {
            return
        }
        
        RFNotification[.currentTimesChanged].send((itemCurrentTime, chapterCurrentTime))
    }
    
    func chapterDidChange(endpointID: UUID, currentChapterIndex: Int?) {
        if current != nil && current?.id != endpointID {
            return
        }
        
        RFNotification[.chapterChanged].send(currentChapterIndex)
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
}
