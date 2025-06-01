//
//  SleepTimerConfiguration.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 04.03.25.
//

import Foundation

public enum SleepTimerConfiguration: Sendable, Hashable {
    case interval(Date)
    case chapters(Int)
    
    var extended: Self {
        switch self {
        case .interval(let remaining):
                .interval(remaining + Defaults[.sleepTimerExtendInterval])
        case .chapters(let amount):
                .chapters(amount + Defaults[.sleepTimerExtendChapterAmount])
        }
    }
}
