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
    
    private(set) var importedConnectionIDs = [String]()
    private(set) var importFailedConnectionIDs = [String]()
    
    private var currentlyPlayingItemID: ItemIdentifier?
    private var tasks = [ItemIdentifier.ConnectionID: Task<Void, Never>]()
    
    init() {
        RFNotification[.changeOfflineMode].subscribe { [weak self] _ in
            self?.importedConnectionIDs.removeAll()
            self?.importFailedConnectionIDs.removeAll()
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
        
        importFailedConnectionIDs.removeAll { $0 == connectionID }
        
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
            
            let connectionCount = await PersistenceManager.shared.authorization.connectionIDs.count
            
            await MainActor.run {
                if success {
                    self.importedConnectionIDs.append(connectionID)
                } else {
                    self.importFailedConnectionIDs.append(connectionID)
                    self.importedConnectionIDs.removeAll(where: { $0 == connectionID })
                }
                
                if self.importFailedConnectionIDs.count == connectionCount {
                    RFNotification[.changeOfflineMode].send(payload: true)
                }
                
                RFNotification[.navigateConditionMet].send()
                
                self.tasks[connectionID] = nil
            }
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
