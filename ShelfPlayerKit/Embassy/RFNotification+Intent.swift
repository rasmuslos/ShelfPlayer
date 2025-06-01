//
//  RFNotification+Intent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Foundation

public extension RFNotification.NonIsolatedNotification {
    static var intentChangePlaybackState: NonIsolatedNotification<Bool> {
        .init("io.rfk.shelfPlayer.embassy.intentChangePlaybackState")
    }
}
