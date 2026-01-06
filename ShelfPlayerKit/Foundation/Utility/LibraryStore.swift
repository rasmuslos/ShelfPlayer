import Foundation
import SwiftUI
import OSLog
import ShelfPlayback

@Observable @MainActor
public final class LibraryStore {
    let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "LibraryStore")

    private(set) public var libraries: [Library] = []
    private(set) public var groupedLibraries: [ItemIdentifier.ConnectionID: [Library]] = [:]

    private init() {
        update()

        RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
            self?.update()
        }
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.update()
        }
    }

    public nonisolated func update() {
        Task {
            guard await !OfflineMode.shared.isEnabled else {
                await MainActor.withAnimation {
                    self.libraries = []
                    self.groupedLibraries = [:]
                }
                
                return
            }

            let libraries = await withTaskGroup {
                for connectionID in await PersistenceManager.shared.authorization.connectionIDs {
                    $0.addTask { try? await ABSClient[connectionID].libraries() }
                }
                
                return await $0.compactMap { $0 }.reduce([], +)
            }
            
            await MainActor.withAnimation {
                self.libraries = libraries
                self.groupedLibraries = Dictionary(grouping: libraries, by: \.id.connectionID)
            }
        }
    }
}

public extension LibraryStore {
    static let shared = LibraryStore()
}
