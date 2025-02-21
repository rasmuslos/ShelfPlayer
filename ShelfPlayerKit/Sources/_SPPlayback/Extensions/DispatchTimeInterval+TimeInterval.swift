//
//  DispatchTimeInterval+TimeInterval.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 11.09.24.
//

import Foundation

public extension DispatchTimeInterval {
    var seconds: TimeInterval? {
        switch self {
            case .seconds(let value):
                TimeInterval(value)
            case .milliseconds(let value):
                TimeInterval(value) * 0.001
            case .microseconds(let value):
                TimeInterval(value) * 0.000_001
            case .nanoseconds(let value):
                TimeInterval(value) * 0.000_000_001
            default:
                nil
        }
    }
}
