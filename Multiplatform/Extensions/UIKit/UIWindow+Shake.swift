//
//  UIWindow+Shake.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 02.10.24.
//

import Foundation
import RFNotifications

#if os(iOS)
import UIKit

@MainActor
var motionStarted: Date?

extension UIWindow {
    open override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else {
            return
        }
        
        motionStarted = .now
    }
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard let motionStarted, motion == .motionShake else {
            return
        }
        
        RFNotification[.shake].send(motionStarted.distance(to: .now))
    }
}
#endif

extension RFNotification.Notification {
    static var shake: Notification<TimeInterval> {
        .init("io.rfk.shelfPlayer.shake")
    }
}
