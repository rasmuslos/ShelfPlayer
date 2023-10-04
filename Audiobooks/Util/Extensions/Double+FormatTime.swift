//
//  Double+FormatTime.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

extension Double {
    func hoursMinutesSeconds() -> (String, String, String) {
        let seconds = Int64(self)
        
        return (
            "\(seconds / 3600)".leftPadding(toLength: 2, withPad: "0"),
            "\((seconds % 3600) / 60)".leftPadding(toLength: 2, withPad: "0"),
            "\((seconds % 3600) % 60)".leftPadding(toLength: 2, withPad: "0")
        )
    }
    
    func hoursMinutesSecondsString() -> String {
        let (hours, minutes, seconds) = hoursMinutesSeconds()
        var result = "\(minutes)m:\(seconds)s"
        
        if hours != "00" {
            result.prefix("\(hours)h:")
        }
        
        return result
    }
}
