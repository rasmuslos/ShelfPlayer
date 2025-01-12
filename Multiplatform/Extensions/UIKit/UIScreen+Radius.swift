//
//  UIScreen+Radius.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 06.05.24.
//

import Foundation
import UIKit

// tomfoolery.
// Taken from https://github.com/kylebshr/ScreenCorners/tree/main

extension UIScreen {
    private var cornerRadiusKey: String {
        ["Radius", "Corner", "display", "_"].reversed().joined()
    }
    
    var displayCornerRadius: CGFloat {
        value(forKey: cornerRadiusKey) as? CGFloat ?? 0
    }
}
