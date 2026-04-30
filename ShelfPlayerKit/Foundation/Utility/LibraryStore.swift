//
//  LibraryStore.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Combine
import Foundation
import OSLog
import SwiftUI

@Observable @MainActor
public final class LibraryStore {
    nonisolated let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "LibraryStore")

    private(set) public var libraries: [Library] = []
    private(set) public var groupedLibraries: [ItemIdentifier.ConnectionID: [Library]] = [:]
    private var observerSubscriptions = Set<AnyCancellable>()

    private init() {
        update()

        OfflineMode.events.changed
            .sink { [weak self] _ in
                self?.update()
            }
            .store(in: &observerSubscriptions)
        PersistenceManager.shared.authorization.events.connectionsChanged
            .sink { [weak self] in
                self?.update()
            }
            .store(in: &observerSubscriptions)
    }

    public nonisolated func update() {
        Task {
            guard await !OfflineMode.shared.isEnabled else {
                await MainActor.run {
                    withAnimation {
                        self.libraries = []
                        self.groupedLibraries = [:]
                    }
                }

                return
            }

            let logger = self.logger
            let libraries = await withTaskGroup(of: [Library]?.self) { group in
                for connectionID in await PersistenceManager.shared.authorization.connectionIDs {
                    group.addTask {
                        do {
                            return try await ABSClient[connectionID].libraries()
                        } catch {
                            logger.warning("Failed to fetch libraries for connection \(connectionID, privacy: .public): \(error, privacy: .public)")
                            return nil
                        }
                    }
                }

                return await group.compactMap { $0 }.reduce([], +)
            }

            await MainActor.run {
                withAnimation {
                    self.libraries = libraries
                    self.groupedLibraries = Dictionary(grouping: libraries, by: \.id.connectionID)
                }
            }
        }
    }
}

public extension LibraryStore {
    static let shared = LibraryStore()
}
