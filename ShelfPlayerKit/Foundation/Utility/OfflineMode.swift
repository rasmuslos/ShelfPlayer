//
//  OfflineMode.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Combine
import Foundation
import OSLog

@Observable @MainActor
public final class OfflineMode: Sendable {
    public final class EventSource: @unchecked Sendable {
        public let changed = PassthroughSubject<Bool, Never>()

        init() {}
    }

    nonisolated public static let availabilityTimeout: TimeInterval = 15
    public nonisolated static let events = EventSource()

    private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "OfflineMode")

    private var availability = [ItemIdentifier.ConnectionID: Bool]()
    private var forcedEnabled = false
    private var activeLoadingOperations = 0
    private var availabilityEstablished = false
    private var establishAvailabilityTask: Task<Void, Never>?
    private var observerSubscriptions = Set<AnyCancellable>()

    private init() {
        PersistenceManager.shared.authorization.events.connectionsChanged
            .sink { [weak self] in
                Task {
                    await self?.refreshAvailability()
                }
            }
            .store(in: &observerSubscriptions)
    }

    public static let shared = OfflineMode()

    public var isEnabled: Bool {
        forcedEnabled || (!availability.isEmpty && availability.values.allSatisfy { !$0 })
    }
    public var isLoading: Bool {
        activeLoadingOperations > 0
    }
}

public extension OfflineMode {
    func markAsUnavailable(_ id: ItemIdentifier.ConnectionID, reason: String = "Connection marked unavailable", file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
        var availability = availability
        availability[id] = false

        applyAvailability(availability, reason: reason, file: file, function: function, line: line)
    }
    func markAsAvailable(_ id: ItemIdentifier.ConnectionID, reason: String = "Connection marked available", file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
        var availability = availability
        availability[id] = true

        applyAvailability(availability, reason: reason, file: file, function: function, line: line)
    }

    func forceEnable(reason: String = "Manual offline mode request", file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) {
        setForcedEnabled(true, reason: reason, file: file, function: function, line: line)
    }

    func isAvailable(_ id: ItemIdentifier.ConnectionID) -> Bool {
        (availability[id] ?? true)
        && !forcedEnabled
    }
}

public extension OfflineMode {
    func refreshAvailability(reason: String = "Connection availability refresh requested", file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) async {
        activeLoadingOperations += 1

        let source = sourceDescription(file: file, function: function, line: line)
        logger.info("Refreshing offline availability. Trigger: \(reason, privacy: .public). Source: \(source, privacy: .public)")

        defer {
            if activeLoadingOperations > 0 {
                activeLoadingOperations -= 1
            }
        }

        setForcedEnabled(false, reason: "Refresh reset forced offline state before probing reachability", file: file, function: function, line: line)

        let availability = await PersistenceManager.shared.authorization.connectionAvailability()
        applyAvailability(availability, reason: "Availability probe completed (\(reason))", file: file, function: function, line: line)
    }

    func ensureAvailabilityEstablished(reason: String = "Initial availability check requested", file: StaticString = #fileID, function: StaticString = #function, line: UInt = #line) async {
        guard !availabilityEstablished else {
            return
        }

        let task: Task<Void, Never>

        if let establishAvailabilityTask {
            task = establishAvailabilityTask
        } else {
            let newTask = Task(priority: .userInitiated) {
                await refreshAvailability(reason: reason, file: file, function: function, line: line)
            }

            establishAvailabilityTask = newTask
            task = newTask
        }

        await task.value

        if establishAvailabilityTask == task {
            establishAvailabilityTask = nil
        }
    }
}

private extension OfflineMode {
    func setForcedEnabled(_ forcedEnabled: Bool, reason: String, file: StaticString, function: StaticString, line: UInt) {
        let source = sourceDescription(file: file, function: function, line: line)
        let before = isEnabled
        let wasForcedEnabled = self.forcedEnabled

        self.forcedEnabled = forcedEnabled

        guard before != isEnabled else {
            self.logger.info("Offline mode unchanged (\(before.description, privacy: .public)). Forced state \(wasForcedEnabled, privacy: .public) -> \(forcedEnabled, privacy: .public). Trigger: \(reason, privacy: .public). Source: \(source, privacy: .public). Availability: \(self.availabilityDescription(self.availability), privacy: .public)")
            return
        }

        if isEnabled {
            self.logger.warning("Offline mode enabled because forced state changed \(wasForcedEnabled, privacy: .public) -> \(forcedEnabled, privacy: .public). Trigger: \(reason, privacy: .public). Source: \(source, privacy: .public). Availability: \(self.availabilityDescription(self.availability), privacy: .public)")
        } else {
            self.logger.info("Offline mode disabled because forced state changed \(wasForcedEnabled, privacy: .public) -> \(forcedEnabled, privacy: .public). Trigger: \(reason, privacy: .public). Source: \(source, privacy: .public). Availability: \(self.availabilityDescription(self.availability), privacy: .public)")
        }

        Self.events.changed.send(isEnabled)
    }

    func applyAvailability(_ availability: [ItemIdentifier.ConnectionID: Bool], reason: String, file: StaticString, function: StaticString, line: UInt) {
        let source = sourceDescription(file: file, function: function, line: line)
        let previousAvailability = self.availability
        let before = isEnabled

        self.availability = availability
        availabilityEstablished = true

        guard before != isEnabled else {
            self.logger.info("Offline mode unchanged (\(before.description, privacy: .public)) after availability update. Trigger: \(reason, privacy: .public). Source: \(source, privacy: .public). Previous availability: \(self.availabilityDescription(previousAvailability), privacy: .public). New availability: \(self.availabilityDescription(availability), privacy: .public)")
            return
        }

        if isEnabled {
            self.logger.warning("Offline mode enabled after availability update. Trigger: \(reason, privacy: .public). Source: \(source, privacy: .public). New availability: \(self.availabilityDescription(availability), privacy: .public)")
        } else {
            self.logger.info("Offline mode disabled after availability update. Trigger: \(reason, privacy: .public). Source: \(source, privacy: .public). New availability: \(self.availabilityDescription(availability), privacy: .public)")
        }

        Self.events.changed.send(isEnabled)
    }

    func sourceDescription(file: StaticString, function: StaticString, line: UInt) -> String {
        "\(file):\(line) \(function)"
    }
    func availabilityDescription(_ availability: [ItemIdentifier.ConnectionID: Bool]) -> String {
        guard !availability.isEmpty else {
            return "<none>"
        }

        return availability
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value ? "online" : "offline")" }
            .joined(separator: ", ")
    }
}
