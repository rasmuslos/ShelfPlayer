//
//  Double+FormatTime.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

public extension Double {
    func hoursMinutesSeconds(padding: Bool = false) -> (String, String, String) {
        let seconds = Int64(self)
        
        if padding {
            return (
                "\(seconds / 3600)".leftPadding(toLength: 2, withPad: "0"),
                "\((seconds % 3600) / 60)".leftPadding(toLength: 2, withPad: "0"),
                "\((seconds % 3600) % 60)".leftPadding(toLength: 2, withPad: "0")
            )
        } else {
            return ("\(seconds / 3600)", "\((seconds % 3600) / 60)", "\((seconds % 3600) % 60)")
        }
    }
    
    func hoursMinutesSecondsString(includeSeconds: Bool = true, includeLabels: Bool = false) -> String {
        let (hours, minutes, seconds) = hoursMinutesSeconds()
        
        let h = includeLabels ? " \(String(localized: "hours", bundle: Bundle.module))" : ""
        let min = includeLabels ? " \(String(localized: "minutes", bundle: Bundle.module))" : ""
        let sec = includeLabels ? " \(String(localized: "seconds", bundle: Bundle.module))" : ""
        let separator = includeLabels ? " " : ":"
        
        var result = ""
        
        if minutes != "" {
            result.append("\(minutes)\(min)")
        }
        if includeSeconds || (hours == "00" && minutes == "00") {
            result.append("\(separator)\(seconds)\(sec)")
        }
        if hours != "00" {
            result.prefix("\(hours)\(h)\(separator)")
        }
        
        return result
    }
    
    func timeLeft(spaceConstrained: Bool = true, includeText: Bool = true) -> String {
        let (hours, minutes, seconds) = self.hoursMinutesSeconds()
        
        let h = spaceConstrained ? "\(String(localized: "hours.letter", bundle: Bundle.module))" : " \(String(localized: "hours", bundle: Bundle.module))"
        let min = " \(String(localized: "minutes.short", bundle: Bundle.module))"
        let sec = spaceConstrained ? "\(String(localized: "seconds.letter", bundle: Bundle.module))" : " \(String(localized: "seconds.short", bundle: Bundle.module))"
        
        let space = spaceConstrained ? " " : ", "
        let text = includeText ? " \(String(localized: "time.left", bundle: Bundle.module))" : ""
        
        if hours != "00" {
            return "\(hours)\(h)\(space)\(minutes)\(min)\(text)"
        } else {
            return "\(minutes)\(min)\(space)\(seconds)\(sec)\(text)"
        }
    }
    
    func numericTimeLeft() -> String {
        let (hours, minutes, seconds) = hoursMinutesSeconds()
        
        if hours != "00" {
            return "\(hours):\(minutes)"
        } else if minutes != "00" {
            return "\(minutes)\(String(localized: "minutes.letter", bundle: Bundle.module))"
        } else {
            return "\(seconds)\(String(localized: "seconds.letter", bundle: Bundle.module))"
        }
    }
    
    func numericDuration() -> String {
        let (hours, minutes, seconds) = hoursMinutesSeconds(padding: false)
        
        if hours != "00" {
            return "\(hours)\(String(localized: "hours.letter", bundle: Bundle.module))"
        } else if minutes != "00" {
            return "\(minutes)\(String(localized: "minutes.letter", bundle: Bundle.module))"
        } else {
            return "\(seconds)\(String(localized: "seconds.letter", bundle: Bundle.module))"
        }
    }
}
