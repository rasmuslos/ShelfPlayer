//
//  SkipController.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI
import OSLog
import ShelfPlayback

@Observable @MainActor
final class SkipController {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "SkipController")

    private let settings = AppSettings.shared

    private(set) var skipCache: TimeInterval?

    @ObservationIgnored
    private(set) var skipTask: Task<Void, Never>?

    private(set) var notifySkipBackwards = false
    private(set) var notifySkipForwards = false

    static let shared = SkipController()

    func skipPressed(forwards: Bool, satellite: Satellite) {
        let isInitial: Bool
        let adjustment = Double(forwards ? settings.skipForwardsInterval : -settings.skipBackwardsInterval)

        logger.info("Skip pressed forwards: \(forwards, privacy: .public) interval: \(adjustment, privacy: .public)")

        if let skipCache {
            isInitial = false
            self.skipCache = skipCache + adjustment
        } else {
            isInitial = true
            self.skipCache = adjustment
        }

        if forwards {
            notifySkipForwards.toggle()
        } else {
            notifySkipBackwards.toggle()
        }

        skipTask?.cancel()
        skipTask = Task {
            try? await Task.sleep(for: .seconds(isInitial ? 0.3 : 0.7))

            guard !Task.isCancelled else {
                return
            }

            if let skipCache {
                self.skipCache = nil
                satellite.seek(to: satellite.currentTime + skipCache, insideChapter: false) {}

                AudioPlayer.shared.events.skipped.send(forwards)
            }
        }
    }
}
