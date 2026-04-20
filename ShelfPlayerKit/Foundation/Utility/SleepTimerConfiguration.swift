//
//  SleepTimerConfiguration.swift
//  ShelfPlayerKit
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

    public func extended(byPreviousSetting: Bool, extendInterval: TimeInterval, extendChapterAmount: Int) -> Self {
        if byPreviousSetting {
            switch self {
            case .interval(let current, let extend):
                    .interval(current.advanced(by: extend), extend)
            case .chapters(let current, let extend):
                    .chapters(current + extend, extend)
            }
        } else {
            switch self {
            case .interval(let remaining, let extend):
                    .interval(remaining + extendInterval, extend)
            case .chapters(let amount, let extend):
                    .chapters(amount + extendChapterAmount, extend)
            }
        }
    }
}
