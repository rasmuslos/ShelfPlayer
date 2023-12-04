//
//  UIDevice+Notch.swift
//  iOS
//
//  Created by Rasmus Krämer on 04.12.23.
//

import Foundation
import UIKit

extension UIDevice {
    /// Returns `true` if the device has a notch
    var hasNotch: Bool {
        guard #available(iOS 11.0, *), let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.filter({$0.isKeyWindow}).first else { return true }
        
        if UIDevice.current.orientation.isPortrait {
            return window.safeAreaInsets.top >= 44
        } else {
            return window.safeAreaInsets.left > 0 || window.safeAreaInsets.right > 0
        }
    }
}
