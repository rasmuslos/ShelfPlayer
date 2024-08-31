//
//  Double+FormatDuration.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.08.24.
//

import Foundation

internal extension Double {
    func formatted<Style: FormatStyle>(_ style: Style) -> Style.FormatOutput where Style.FormatInput == Duration {
        Duration.seconds(self).formatted(style)
    }
}

internal struct DurationComponentsFormatter: FormatStyle {
    var unitsStyle: DateComponentsFormatter.UnitsStyle
    var allowedUnits: NSCalendar.Unit
    var maximumUnitCount: Int
    
    init(unitsStyle: DateComponentsFormatter.UnitsStyle = .abbreviated, allowedUnits: NSCalendar.Unit = [.hour, .minute], maximumUnitCount: Int = 2) {
        self.unitsStyle = unitsStyle
        self.allowedUnits = allowedUnits
        self.maximumUnitCount = maximumUnitCount
    }
    
    mutating func unitsStyle(_ unitsStyle: DateComponentsFormatter.UnitsStyle) -> Self {
        self.unitsStyle = unitsStyle
        return self
    }
    
    mutating func allowedUnits(_ allowedUnits: NSCalendar.Unit) -> Self {
        self.allowedUnits = allowedUnits
        return self
    }
    
    mutating func maximumUnitCount(_ maximumUnitCount: Int) -> Self {
        self.maximumUnitCount = maximumUnitCount
        return self
    }
    
    func format(_ value: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = unitsStyle
        formatter.allowedUnits = allowedUnits
        formatter.maximumUnitCount = maximumUnitCount
        
        if unitsStyle == .positional {
            formatter.collapsesLargestUnit = false
            formatter.zeroFormattingBehavior = .pad
        } else {
            formatter.collapsesLargestUnit = true
            formatter.zeroFormattingBehavior = .dropLeading
        }
        
        formatter.allowsFractionalUnits = false
        
        return formatter.string(from: value)!
    }
}

internal extension FormatStyle where Self == DurationComponentsFormatter {
    static var duration: DurationComponentsFormatter {
        .init()
    }
    static func duration(unitsStyle: DateComponentsFormatter.UnitsStyle = .abbreviated, allowedUnits: NSCalendar.Unit = [.hour, .minute], maximumUnitCount: Int = 2) -> DurationComponentsFormatter {
        .init(unitsStyle: unitsStyle, allowedUnits: allowedUnits, maximumUnitCount: maximumUnitCount)
    }
}

extension NSCalendar.Unit: Codable, @retroactive Hashable {}
extension DateComponentsFormatter.UnitsStyle: Codable, @retroactive Hashable {}
