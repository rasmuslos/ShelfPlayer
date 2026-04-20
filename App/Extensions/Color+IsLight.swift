//
//  Color+IsLight.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.08.24.
//

import Foundation
import SwiftUI

internal extension Color {
    var isLight: Bool? {
        isLight(threshold: 0.6)
    }

    func isLight(threshold: Float) -> Bool? {
        guard let originalCGColor = self.cgColor else {
            return nil
        }

        let RGBCGColor = originalCGColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)

        guard let components = RGBCGColor?.components else {
            return nil
        }
        guard components.count >= 3 else {
            return nil
        }

        let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)

        return (brightness > threshold)
    }
}
