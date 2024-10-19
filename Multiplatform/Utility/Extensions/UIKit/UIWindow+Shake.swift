//
//  UIWindow+Shake.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 02.10.24.
//

import Foundation
import UIKit

extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: Self.deviceDidShakeNotification, object: nil)
        }
     }
    
    internal static let deviceDidShakeNotification = Notification.Name(rawValue: "io.rfk.shelfPlayer.shake")
}
