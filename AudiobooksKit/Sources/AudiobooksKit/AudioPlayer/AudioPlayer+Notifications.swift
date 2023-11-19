//
//  AudioPlayer+Notifications.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import Foundation

extension AudioPlayer {
    public static let playPauseNotification = NSNotification.Name("io.rfk.audiobooks.playPause")
    public static let startStopNotification = NSNotification.Name("io.rfk.audiobooks.startStop")
    public static let currentTimeChangedNotification = NSNotification.Name("io.rfk.audiobooks.currentTime.changed")
    public static let playbackRateChanged = NSNotification.Name("io.rfk.audiobooks.rate.changed")
    public static let sleepTimerChanged = NSNotification.Name("io.rfk.audiobooks.sleeptimer.changed")
}
