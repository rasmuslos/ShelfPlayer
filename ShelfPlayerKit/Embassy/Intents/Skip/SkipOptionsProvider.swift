//
//  SkipOptionsProvider.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

struct SkipOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [TimeInterval] {
        [15, 30, 45, 60, 90, 120]
    }
}
