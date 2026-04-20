//
//  SleepTimerLiveActivityAttributes.swift
//  ShelfPlayerKit
//

import Foundation
import ActivityKit

public struct SleepTimerLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let deadline: Date?
        public let chapters: Int?

        public let isPlaying: Bool

        public init(deadline: Date?, chapters: Int?, isPlaying: Bool) {
            self.deadline = deadline
            self.chapters = chapters
            self.isPlaying = isPlaying
        }
    }

    public let started: Date

    public init(started: Date) {
        self.started = started
    }
}
