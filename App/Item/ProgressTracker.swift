//
//  ProgressTracker.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 24.02.25.
//

import SwiftUI
import Combine
import OSLog
import ShelfPlayback

@Observable @MainActor
final class ProgressTracker {
    private var observerSubscriptions = Set<AnyCancellable>()

    let itemID: ItemIdentifier

    var progress: Percentage?

    var duration: TimeInterval?
    var currentTime: TimeInterval?

    var startedAt: Date?
    var lastUpdate: Date?
    var finishedAt: Date?

    var isValid: Bool?

    init(itemID: ItemIdentifier) {
        self.itemID = itemID

        load()

        PersistenceManager.shared.progress.events.invalidateCache
            .sink { [weak self] connectionID in
                Task { @MainActor [weak self] in
                    guard let self, connectionID == nil || connectionID == itemID.connectionID else {
                        return
                    }

                    self.load()
                }
            }
            .store(in: &observerSubscriptions)

        PersistenceManager.shared.progress.events.entityUpdated
            .sink { [weak self] payload in
                Task { @MainActor [weak self] in
                    guard let self,
                          payload.connectionID == itemID.connectionID,
                          payload.primaryID == itemID.primaryID,
                          payload.groupingID == itemID.groupingID else {
                        return
                    }

                    guard let entity = payload.3 else {
                        self.progress = 0
                        self.currentTime = 0

                        self.startedAt = nil
                        self.finishedAt = nil

                        self.lastUpdate = .now
                        self.isValid = false

                        return
                    }

                    self.progress = entity.progress

                    self.duration = entity.duration
                    self.currentTime = entity.currentTime

                    self.startedAt = entity.startedAt
                    self.lastUpdate = entity.lastUpdate
                    self.finishedAt = entity.finishedAt
                }
            }
            .store(in: &observerSubscriptions)
    }

    func load() {
        Task { [itemID] in
            let entity = await withTimeout(seconds: 3) {
                await ProgressCache.shared.entity(for: itemID)
            }

            if let entity {
                self.progress = entity.progress
                self.duration = entity.duration
                self.currentTime = entity.currentTime
                self.startedAt = entity.startedAt
                self.lastUpdate = entity.lastUpdate
                self.finishedAt = entity.finishedAt
            } else {
                self.progress = 0
            }

            isValid = true
        }
    }

    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(seconds))
                return nil
            }

            if let first = await group.next(), let result = first {
                group.cancelAll()
                return result
            }
            if let second = await group.next(), let result = second {
                group.cancelAll()
                return result
            }

            group.cancelAll()
            return nil
        }
    }

    public var isFinished: Bool? {
        if let progress {
            progress >= 1
        } else {
            nil
        }
    }
}

private actor ProgressCache: Sendable {
    private nonisolated let observerSubscriptions: [AnyCancellable]

    var cached = [ItemIdentifier: Task<ProgressEntity, Never>]()

    private init() {
        let invalidateSubscription = PersistenceManager.shared.progress.events.invalidateEntities
            .sink { connectionID in
                Task {
                    await ProgressCache.shared.invalidateAndPropagate(connectionID: connectionID)
                }
            }
        let updateSubscription = PersistenceManager.shared.progress.events.entityUpdated
            .sink { payload in
                Task {
                    await ProgressCache.shared.invalidate(connectionID: payload.connectionID, primaryID: payload.primaryID, groupingID: payload.groupingID)
                }
            }
        observerSubscriptions = [invalidateSubscription, updateSubscription]
    }

    func entity(for itemID: ItemIdentifier) async -> ProgressEntity {
        if cached[itemID] == nil {
            cached[itemID] = Task.detached {
                await PersistenceManager.shared.progress[itemID]
            }
        }

        return await cached[itemID]!.value
    }

    private func invalidateAndPropagate(connectionID: ItemIdentifier.ConnectionID?) async {
        guard let connectionID else {
            cached.removeAll()
            return
        }

        let keys = cached.keys.filter {
            $0.connectionID == connectionID
        }

        for key in keys {
            cached[key] = nil
        }

        PersistenceManager.shared.progress.events.invalidateCache.send(connectionID)
    }
    private func invalidate(connectionID: ItemIdentifier.ConnectionID, primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?) {
        let keys = cached.keys.filter {
            $0.connectionID == connectionID
                && $0.primaryID == primaryID
                && $0.groupingID == groupingID
        }

        for key in keys {
            cached[key] = nil
        }
    }

    nonisolated static let shared = ProgressCache()
}
