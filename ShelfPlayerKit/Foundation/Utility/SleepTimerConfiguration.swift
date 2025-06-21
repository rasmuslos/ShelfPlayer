//
//  SleepTimerConfiguration.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import Foundation

public enum SleepTimerConfiguration: Sendable, Hashable {
    case interval(Date)
    case chapters(Int)
    
    public var extended: Self {
        switch self {
        case .interval(let remaining):
                .interval(remaining + Defaults[.sleepTimerExtendInterval])
        case .chapters(let amount):
                .chapters(amount + Defaults[.sleepTimerExtendChapterAmount])
        }
    }
}
