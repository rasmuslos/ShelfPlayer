//
//  AudioPlayer+Notifications.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation

public extension AudioPlayer {
    static let itemDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.item")
    static let playingDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.playing")
    
    static let chapterDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.chapter")
    static let chaptersDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.chapters")
    static let bufferingDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.buffering")
    
    static let timeDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.time")
    static let speedDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.speed")
    static let queueDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.queue")
    
    static let routeDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.route")
    static let volumeDidChangeNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.updates.volume")
    
    static let backwardsNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.backwards")
    static let forwardsNotification = Notification.Name("io.rfk.shelfPlayer.audioPlayer.forwards")
}
