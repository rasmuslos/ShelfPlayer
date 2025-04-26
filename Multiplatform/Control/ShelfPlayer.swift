//
//  ShelfPlayer.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.03.25.
//

import Foundation
import OSLog
import Intents
import TipKit
import Nuke
import Defaults
import ShelfPlayerKit

struct ShelfPlayer {
    static let logger = Logger(subsystem: "io.rfk.ShelfPlayer", category: "Hooks")
    
    // MARK: Hooks
    
    static func launchHook() {
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        
        do {
            try Tips.configure()
        } catch {
            logger.error("Failed to configure tips: \(error)")
        }
        
        RFNotification[.removeConnection].subscribe { connectionID in
            Defaults[.carPlayTabBarLibraries]?.removeAll {
                $0.connectionID == connectionID
            }
        }
    }
    
    static func initializeHook() {
        #if ENABLE_CENTRALIZED
        INPreferences.requestSiriAuthorization {
            logger.info("Got Siri authorization status: \($0.rawValue)")
        }
        #endif
        
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await PersistenceManager.shared.download.invalidateActiveDownloads() }
                $0.addTask {
                    do {
                        try await PersistenceManager.shared.session.attemptSync(early: false)
                    } catch {
                        logger.error("Failed to sync sessions: \(error)")
                    }
                }
                
                $0.addTask { await ContextProvider.updateUserContext() }
                
                await $0.waitForAll()
            }
        }
    }
    
    static func updateUIHook() {
        PersistenceManager.shared.download.scheduleUpdateTask()
        RFNotification[.invalidateProgressEntities].send(nil)
    }
    
    // MARK: Actions
    
    static func clearCache() {
        ImagePipeline.shared.cache.removeAll()
    }
    
    static func generateLogArchive() throws -> URL {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let predicate = NSPredicate(format: "subsystem BEGINSWITH %@", "io.rfk.")
        
        let all = try store.getEntries()
        let filtered = try store.getEntries(matching: predicate)
        
        let name = Date.now.formatted(.iso8601)
        let baseURL = FileManager.default.temporaryDirectory.appending(path: name)
        
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        
        try writeLogEntitiesToFile(all, at: baseURL.appending(path: "ShelfPlayerAll.log"))
        try writeLogEntitiesToFile(filtered, at: baseURL.appending(path: "ShelfPlayerFiltered.log"))
        
        var error: NSError?
        var moveError: Error?
        
        let coordinator = NSFileCoordinator()
        
        let targetURL = FileManager.default.temporaryDirectory.appending(path: "\(name).log.zip")
        
        coordinator.coordinate(readingItemAt: baseURL, options: .forUploading, error: &error) {
            do {
                try FileManager.default.moveItem(at: $0, to: targetURL)
            } catch {
                moveError = error
            }
        }
        
        if let error = error ?? moveError {
            logger.error("Failed to create zip log archive: \(error)")
            throw error
        }
        
        return targetURL
    }
    
    // MARK: Cache invalidation
    
    static func invalidateCache() async {
        logger.info("Invalidating short term cache...")
        
        await ResolveCache.shared.invalidate()
        await ProgressTrackerCache.shared.invalidate()
        await DownloadTrackerCache.shared.invalidate()
    }
}

private extension ShelfPlayer {
    static func writeLogEntitiesToFile(_ entities: AnySequence<OSLogEntry>, at url: URL) throws {
        try entities.map {
            "\($0.date.formatted(.iso8601)): \($0.composedMessage)"
        }.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }
}
