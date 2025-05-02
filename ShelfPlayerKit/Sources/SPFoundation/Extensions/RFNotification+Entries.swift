//
//  RFNotification+Entries.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.05.25.
//

import Foundation
import RFNotifications

public extension RFNotification.Notification {
    static var playbackItemChanged: Notification<(ItemIdentifier, [Chapter], TimeInterval)> { .init("io.rfk.shelfPlayerKit.playbackItemChanged") }
    static var playStateChanged: Notification<(Bool)> { .init("io.rfk.shelfPlayerKit.playStateChanged") }
    
    static var skipped: Notification<(Bool)> { .init("io.rfk.shelfPlayerKit.skipped") }
    
    static var bufferHealthChanged: Notification<(Bool)> { .init("io.rfk.shelfPlayerKit.bufferHealthChanged") }
    
    static var durationsChanged: Notification<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?)> { .init("io.rfk.shelfPlayerKit.durationsChanged") }
    static var currentTimesChanged: Notification<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?)> { .init("io.rfk.shelfPlayerKit.currentTimesChanged") }
    
    static var chapterChanged: Notification<Chapter?> { .init("io.rfk.shelfPlayerKit.chapterChanged") }
    
    static var volumeChanged: Notification<Percentage> { .init("io.rfk.shelfPlayerKit.volumeChanged") }
    static var playbackRateChanged: Notification<Percentage> { .init("io.rfk.shelfPlayerKit.playbackRateChanged") }
    
    static var queueChanged: Notification<[ItemIdentifier]> { .init("io.rfk.shelfPlayerKit.queueChanged") }
    static var upNextQueueChanged: Notification<[ItemIdentifier]> { .init("io.rfk.shelfPlayerKit.upNextQueueChanged") }
    
    static var playbackStopped: Notification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.playbackStopped") }
    
    static var shake: Notification<TimeInterval> { .init("io.rfk.shelfPlayer.shake") }
    static var finalizePlaybackReporting: Notification<RFNotificationEmptyPayload> { .init("io.rfk.shelfPlayerKit.finalizePlaybackReporting") }
}
