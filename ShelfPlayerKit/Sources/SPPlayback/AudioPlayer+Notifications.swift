//
//  AudioPlayer+Notifications.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation

public extension AudioPlayer {
    static let itemDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.item")
    static let playingDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.playing")
    
    static let chapterDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.chapter")
    static let chaptersDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.chapters")
    static let bufferingDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.buffering")
    
    static let timeDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.time")
    static let speedDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.speed")
    static let queueDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.queue")
    
    static let volumeDidChangeNotification = Notification.Name("io.rfk.ampfin.audioPlayer.updates.volume")
}
