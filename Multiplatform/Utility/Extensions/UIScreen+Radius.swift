//
//  UIScreen+Radius.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 06.05.24.
//

import Foundation
import UIKit

// Lets do a little UIKit tomfoolery
// Taken from https://github.com/kylebshr/ScreenCorners/tree/main

extension UIScreen {
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()
    
    public var displayCornerRadius: CGFloat {
        guard let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            assertionFailure("Failed to detect screen corner radius")
            return 0
        }
        
        return cornerRadius
    }
}
