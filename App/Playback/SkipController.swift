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

    @ObservationIgnored
    private var holdTimer: Timer?
    @ObservationIgnored
    private var holdStartedAt: Date?

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

    func longPressStarted(forwards: Bool, satellite: Satellite) {
        holdStartedAt = Date()
        holdTimer?.invalidate()
        scheduleHoldTick(forwards: forwards, satellite: satellite)
    }

    func longPressEnded() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdStartedAt = nil
    }

    private func scheduleHoldTick(forwards: Bool, satellite: Satellite) {
        let elapsed = holdStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let interval: TimeInterval = switch elapsed {
        case ..<1.5: 0.28
        case ..<3.0: 0.16
        default: 0.09
        }

        holdTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.skipPressed(forwards: forwards, satellite: satellite)
                self.scheduleHoldTick(forwards: forwards, satellite: satellite)
            }
        }
    }
}
