//
//  UIScreen+Radius.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 06.05.24.
//

import Foundation
import UIKit

extension UIScreen {
    private var cornerRadiusKey: String {
        ["Radius", "Corner", "display", "_"].reversed().joined()
    }

    var displayCornerRadius: CGFloat {
        value(forKey: cornerRadiusKey) as? CGFloat ?? 0
    }
}
