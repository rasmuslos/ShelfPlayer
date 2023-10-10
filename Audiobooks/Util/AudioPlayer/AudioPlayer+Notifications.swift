//
//  AudioPlayer+Notifications.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import Foundation

extension AudioPlayer {
    static let playPauseNotification = NSNotification.Name("io.rfk.audiobooks.playPause")
    static let startStopNotification = NSNotification.Name("io.rfk.audiobooks.startStop")
}
