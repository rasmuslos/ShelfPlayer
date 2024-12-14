//
//  tmptest.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 14.12.24.
//

import Foundation
import Defaults

public var stops: [StopEvent] = Defaults[.stopReasons] {
    didSet {
        Defaults[.stopReasons] = stops
    }
}

public struct StopEvent: Codable, Defaults.Serializable {
    public let time: Date
    public let reason: StopReason
}
public enum StopReason: Codable {
    case newItem
    case queueEmpty
    case seekExceededDuration
    case queueIndexOutOfBounds
    case playerTimeout
    case advanceFailed
    case userRequest
    
    case sleepChapter
    case sleepTime
    
    public var label: String {
        switch self {
        case .newItem:
            "newItem"
        case .queueEmpty:
            "queueEmpty"
        case .seekExceededDuration:
            "seekExceededDuration"
        case .queueIndexOutOfBounds:
            "queueIndexOutOfBounds"
        case .playerTimeout:
            "playerTimeout"
        case .advanceFailed:
            "advancedFailed"
        case .userRequest:
            "userRequest"
        case .sleepChapter:
            "sleepChapter"
        case .sleepTime:
            "sleepTime"
        }
    }
}

public func clearStops() {
    Defaults.reset(.stopReasons)
}

private extension Defaults.Keys {
    static let stopReasons = Key<[StopEvent]>("stopReason", default: [])
}
