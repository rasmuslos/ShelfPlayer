//
//  Color+IsLight.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.08.24.
//

import Foundation
import SwiftUI

internal extension Color {
    var isLight: Bool {
        isLight() ?? false
    }
    
    func isLight(threshold: Float = 0.6) -> Bool? {
        guard let originalCGColor = self.cgColor else {
            return nil
        }
        
        // Now we need to convert it to the RGB colorspace. UIColor.white / UIColor.black are greyscale and not RGB.
        // If you don't do this then you will crash when accessing components index 2 below when evaluating greyscale colors.
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
