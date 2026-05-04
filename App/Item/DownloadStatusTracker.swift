//
//  DownloadStatusTracker.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 24.02.25.
//

import SwiftUI
import Combine
import ShelfPlayback

@Observable @MainActor
final class DownloadStatusTracker {
    private var observerSubscriptions = Set<AnyCancellable>()

    let itemID: ItemIdentifier
    var status: DownloadStatus?

    init(itemID: ItemIdentifier) {
        self.itemID = itemID

        load()

        PersistenceManager.shared.download.events.statusChanged
            .sink { [weak self] payload in
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    guard let (itemID, status) = payload else {
                        self.load()
                        return
                    }

                    guard self.itemID == itemID else {
                        return
                    }

                    withAnimation {
                        self.status = status
                    }
                }
            }
            .store(in: &observerSubscriptions)
    }

    private func load() {
        Task {
            let status = await DownloadStatusCache.shared.status(for: itemID)

            withAnimation {
                self.status = status
            }
        }
    }
}

private actor DownloadStatusCache: Sendable {
    private nonisolated let observerSubscription: AnyCancellable

    var cached = [ItemIdentifier: Task<DownloadStatus, Never>]()

    private init() {
        observerSubscription = PersistenceManager.shared.download.events.statusChanged
            .sink { payload in
                Task {
                    await DownloadStatusCache.shared.invalidate(payload: payload)
                }
            }
    }

    func status(for itemID: ItemIdentifier) async -> DownloadStatus {
        if cached[itemID] == nil {
            cached[itemID] = Task.detached {
                await PersistenceManager.shared.download.status(of: itemID)
            }
        }

        return await cached[itemID]!.value
    }

    private func invalidate(payload: (itemID: ItemIdentifier, status: DownloadStatus)?) {
        guard let payload else {
            cached.removeAll()
            return
        }

        cached[payload.itemID] = Task {
            payload.status
        }
    }

    nonisolated static let shared = DownloadStatusCache()
}
