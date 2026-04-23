//
//  Double+FormatRate.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 22.08.25.
//

import Foundation

public struct PlaybackRateFormatter: FormatStyle {
    var hideX: Bool = false
    var fixedFractionDigits: Int?

    public func hideX(_ hideX: Bool = true) -> Self {
        var copy = self
        copy.hideX = hideX
        return copy
    }

    public func fractionDigits(_ digits: Int) -> Self {
        var copy = self
        copy.fixedFractionDigits = digits
        return copy
    }

    public func format(_ value: TimeInterval) -> String {
        guard value.isFinite && !value.isNaN else {
            return "?"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = false

        if let fixedFractionDigits {
            formatter.minimumFractionDigits = fixedFractionDigits
            formatter.maximumFractionDigits = fixedFractionDigits
        } else {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
        }

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
