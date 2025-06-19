//
//  SkipOptionsProvider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.06.25.
//

import Foundation
import AppIntents

struct SkipOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [TimeInterval] {
        [15, 30, 45, 60, 90, 120]
    }
}
