//
//  SleepTimerConfiguration.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import Foundation

public enum SleepTimerConfiguration: Sendable, Hashable, Codable {
    case interval(Date, TimeInterval)
    case chapters(Int, Int)
    
    public static func interval(_ timeout: TimeInterval) -> Self {
        .interval(.now.advanced(by: timeout), timeout)
    }
    public static func chapters(_ amount: Int) -> Self {
        .chapters(amount, amount)
    }
    
    public var reset: Self {
        switch self {
            case .interval(_, let original):
                .interval(.now.advanced(by: original), original)
            case .chapters(_, let original):
                .chapters(original, original)
        }
    }

    public var extended: Self {
        if Defaults[.extendSleepTimerByPreviousSetting] {
            switch self {
                case .interval(let current, let extend):
                        .interval(current.advanced(by: extend), extend)
                case .chapters(let current, let extend):
                        .chapters(current + extend, extend)
            }
        } else {
            switch self {
                case .interval(let remaining, let extend):
                        .interval(remaining + Defaults[.sleepTimerExtendInterval], extend)
                case .chapters(let amount, let extend):
                        .chapters(amount + Defaults[.sleepTimerExtendChapterAmount], extend)
            }
        }
    }
}
