//
//  ProgressViewModel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.05.25.
//

import SwiftUI
import OSLog
import ShelfPlayback

@MainActor @Observable
final class ProgressViewModel {
    let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "ProgressViewModel")
    
    private(set) var importedConnectionIDs = Set<String>()
    private(set) var importFailedConnectionIDs = Set<String>()
    
    private var currentlyPlayingItemID: ItemIdentifier?
    private var tasks = [ItemIdentifier.ConnectionID: Task<Void, Never>]()
    
    private init() {
        RFNotification[.offlineModeChanged].subscribe { [weak self] isEnabled in
            guard !isEnabled else {
                return
            }
            
            self?.importedConnectionIDs.removeAll()
            self?.importFailedConnectionIDs.removeAll()
            
            self?.syncAllConnections()
        }
        
        RFNotification[.playbackItemChanged].subscribe { [weak self] in
            self?.currentlyPlayingItemID = $0.0
            self?.attemptSync(for: $0.0.connectionID)
        }
        RFNotification[.playbackStopped].subscribe { [weak self] _ in
            guard let currentlyPlayingItemID = self?.currentlyPlayingItemID else {
                return
            }
            
            self?.currentlyPlayingItemID = nil
            self?.attemptSync(for: currentlyPlayingItemID.connectionID)
        }
        
        RFNotification[.performBackgroundSessionSync].subscribe { [weak self] connectionID in
            if let connectionID {
                self?.attemptSync(for: connectionID)
            } else {
                self?.syncAllConnections()
            }
        }
    }
    
    func attemptSync(for connectionID: ItemIdentifier.ConnectionID) {
        guard tasks[connectionID] == nil else {
            logger.warning("Tried to start sync for \(connectionID) while it is already running")
            return
        }
        
        importFailedConnectionIDs.remove(connectionID)
        
        tasks[connectionID] = Task.detached {
            let success: Bool
            let task = await UIApplication.shared.beginBackgroundTask(withName: "synchronizeUserData")
            
            do {
                
                let (sessions, bookmarks) = try await ABSClient[connectionID].authorize()
                
                try await withThrowingTaskGroup(of: Void.self) {
                    $0.addTask { try await PersistenceManager.shared.progress.sync(sessions: sessions, connectionID: connectionID) }
                    $0.addTask { try await PersistenceManager.shared.bookmark.sync(bookmarks: bookmarks, connectionID: connectionID) }
                    
                    try await $0.waitForAll()
                }
                
                success = true
            } catch {
                self.logger.error("Failed to synchronize \(connectionID, privacy: .public): \(error, privacy: .public)")
                success = false
            }
            
            await UIApplication.shared.endBackgroundTask(task)
            
            await MainActor.run {
                if success {
                    self.importedConnectionIDs.insert(connectionID)
                } else {
                    self.importFailedConnectionIDs.insert(connectionID)
                    self.importedConnectionIDs.remove(connectionID)
                }
                
                self.tasks[connectionID] = nil
                
                if self.tasks.isEmpty && self.importedConnectionIDs.isEmpty {
                    OfflineMode.shared.setEnabled(true)
                }
            }
        }
    }
    
    func flush(isLoading: Binding<Bool>) {
        Task {
            isLoading.wrappedValue = true
            
            importedConnectionIDs.removeAll()
            importFailedConnectionIDs.removeAll()
            
            try! await PersistenceManager.shared.progress.flush()
            
            syncAllConnections()
            
            try await Task.sleep(for: .seconds(1))
            
            isLoading.wrappedValue = false
        }
    }
}

private extension ProgressViewModel {
    func syncAllConnections() {
        Task {
            for connectionID in await PersistenceManager.shared.authorization.connectionIDs {
                attemptSync(for: connectionID)
            }
        }
    }
}

extension ProgressViewModel {
    static let shared = ProgressViewModel()
}
