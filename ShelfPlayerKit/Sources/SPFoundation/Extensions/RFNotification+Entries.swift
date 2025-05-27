//
//  RFNotification+Entries.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.05.25.
//

import Foundation
import RFNotifications

public extension RFNotification.IsolatedNotification {
    static var playbackItemChanged: IsolatedNotification<(ItemIdentifier, [Chapter], TimeInterval)> { .init("io.rfk.shelfPlayerKit.playbackItemChanged") }
    static var playStateChanged: IsolatedNotification<(Bool)> { .init("io.rfk.shelfPlayerKit.playStateChanged") }
    
    static var skipped: IsolatedNotification<(Bool)> { .init("io.rfk.shelfPlayerKit.skipped") }
    
    static var bufferHealthChanged: IsolatedNotification<(Bool)> { .init("io.rfk.shelfPlayerKit.bufferHealthChanged") }
    
    static var durationsChanged: IsolatedNotification<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?)> { .init("io.rfk.shelfPlayerKit.durationsChanged") }
    static var currentTimesChanged: IsolatedNotification<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?)> { .init("io.rfk.shelfPlayerKit.currentTimesChanged") }
    
    static var chapterChanged: IsolatedNotification<Chapter?> { .init("io.rfk.shelfPlayerKit.chapterChanged") }
    
    static var volumeChanged: IsolatedNotification<Percentage> { .init("io.rfk.shelfPlayerKit.volumeChanged") }
    static var playbackRateChanged: IsolatedNotification<Percentage> { .init("io.rfk.shelfPlayerKit.playbackRateChanged") }
    
    static var queueChanged: IsolatedNotification<[ItemIdentifier]> { .init("io.rfk.shelfPlayerKit.queueChanged") }
    static var upNextQueueChanged: IsolatedNotification<[ItemIdentifier]> { .init("io.rfk.shelfPlayerKit.upNextQueueChanged") }
    
    static var playbackStopped: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.playbackStopped") }
    
    static var synchronizedPlaybackSessions: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.synchronizedPlaybackSessions") }
    static var cachedTimeSpendListeningChanged: IsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.cachedTimeSpendListeningChanged") }
}

public extension RFNotification.NonIsolatedNotification {
    static var shake: NonIsolatedNotification<TimeInterval> { .init("io.rfk.shelfPlayer.shake") }
    static var finalizePlaybackReporting: NonIsolatedNotification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.finalizePlaybackReporting") }
}
