//
//  DownloadAccessibilityAnnouncer.swift
//  ShelfPlayer
//

import Combine
import UIKit
import ShelfPlayback

final class DownloadAccessibilityAnnouncer: Sendable {
    static let shared = DownloadAccessibilityAnnouncer()

    private let subscriptions: [AnyCancellable]

    private init() {
        let statusSubscription = PersistenceManager.shared.download.events.statusChanged
            .sink { payload in
                Task { @MainActor in
                    DownloadAnnouncerState.shared.handleStatus(payload)
                }
            }

        let progressSubscription = PersistenceManager.shared.download.events.progressChanged
            .sink { payload in
                Task { @MainActor in
                    DownloadAnnouncerState.shared.handleProgress(payload)
                }
            }

        subscriptions = [statusSubscription, progressSubscription]
    }
}

@MainActor
private final class DownloadAnnouncerState {
    static let shared = DownloadAnnouncerState()
    private init() {}

    private struct ItemState {
        var baseProgress: Percentage = 0
        var baseProgressLoaded = false
        var metadata: [UUID: (weight: Percentage, total: Int64)] = [:]
        var progress: [UUID: Int64] = [:]
        var announcedMilestones: Set<Int> = []

        var current: Percentage {
            var result = baseProgress
            for (assetID, info) in metadata {
                guard let bytes = progress[assetID] else { continue }
                if info.total > 0 {
                    result += (Percentage(bytes) / Percentage(info.total)) * info.weight
                } else {
                    result += info.weight
                }
            }
            return result
        }
    }

    private static let milestonePercent = 50

    private var items = [ItemIdentifier: ItemState]()

    func handleStatus(_ payload: (itemID: ItemIdentifier, status: DownloadStatus)?) {
        guard let payload else { return }

        switch payload.status {
        case .completed:
            items.removeValue(forKey: payload.itemID)
            Task { await postAnnouncement(itemID: payload.itemID, percent: nil) }
        case .none:
            items.removeValue(forKey: payload.itemID)
        case .downloading:
            ensureState(for: payload.itemID)
        }
    }

    func handleProgress(_ payload: PersistenceManager.DownloadSubsystem.EventSource.ProgressPayload) {
        ensureState(for: payload.itemID)

        var state = items[payload.itemID] ?? ItemState()
        state.metadata[payload.assetID] = (payload.weight, payload.totalBytesExpectedToWrite)

        if state.progress[payload.assetID] == nil {
            state.progress[payload.assetID] = payload.totalBytesWritten
        } else {
            state.progress[payload.assetID]! += payload.bytesWritten
        }

        items[payload.itemID] = state
        checkMilestone(for: payload.itemID)
    }

    private func ensureState(for itemID: ItemIdentifier) {
        guard items[itemID] == nil else { return }
        items[itemID] = ItemState()
        loadBaseProgress(for: itemID)
    }

    private func loadBaseProgress(for itemID: ItemIdentifier) {
        Task { @MainActor in
            let progress = await PersistenceManager.shared.download.downloadProgress(of: itemID)
            guard items[itemID] != nil else { return }
            items[itemID]?.baseProgress = progress
            items[itemID]?.baseProgressLoaded = true
            checkMilestone(for: itemID)
        }
    }

    private func checkMilestone(for itemID: ItemIdentifier) {
        guard var state = items[itemID], state.baseProgressLoaded else { return }

        let currentPercent = Int(state.current * 100)
        let milestone = Self.milestonePercent

        if currentPercent >= milestone, !state.announcedMilestones.contains(milestone) {
            state.announcedMilestones.insert(milestone)
            items[itemID] = state
            Task { await postAnnouncement(itemID: itemID, percent: milestone) }
        }
    }

    private func postAnnouncement(itemID: ItemIdentifier, percent: Int?) async {
        guard UIAccessibility.isVoiceOverRunning else { return }

        let title = (try? await itemID.resolved)?.name
        let message: String

        if let percent {
            if let title, !title.isEmpty {
                message = String(localized: "download.progress.announcement \(title) \(percent)")
            } else {
                message = String(localized: "download.progress.announcement.generic \(percent)")
            }
        } else if let title, !title.isEmpty {
            message = String(localized: "download.complete.announcement \(title)")
        } else {
            message = String(localized: "download.complete.announcement.generic")
        }

        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
