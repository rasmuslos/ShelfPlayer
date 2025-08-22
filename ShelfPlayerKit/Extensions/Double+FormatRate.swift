//
//  Double+FormatRate.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 22.08.25.
//

import Foundation

public struct PlaybackRateFormatter: FormatStyle {
    var hideX: Bool = false
    
    public func hideX(_ hideX: Bool = true) -> Self {
        .init(hideX: true)
    }
    
    public func format(_ value: TimeInterval) -> String {
        guard value.isFinite && !value.isNaN else {
            return "?"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = false
        
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let result = formatter.string(from: value as NSNumber) ?? "?"
        
        if hideX {
            return result
        }
        
        return "\(result)x"
    }
}

public extension FormatStyle where Self == PlaybackRateFormatter {
    static var playbackRate: PlaybackRateFormatter {
        .init()
    }
}
