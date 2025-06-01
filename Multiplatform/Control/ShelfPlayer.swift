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
import ShelfPlayback

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
    
    static func initializeUIHook() {
        #if ENABLE_CENTRALIZED
        INPreferences.requestSiriAuthorization {
            logger.info("Got Siri authorization status: \($0.rawValue)")
        }
        #endif
        
        SpotlightIndexer.shared.run()
        
        Task {
            await withTaskGroup {
                $0.addTask { await PersistenceManager.shared.download.invalidateActiveDownloads() }
                $0.addTask {
                    do {
                        try await PersistenceManager.shared.session.attemptSync(early: false)
                    } catch {
                        logger.error("Failed to sync sessions: \(error)")
                    }
                }
                
                $0.addTask { await ListenNowCache.shared.preload() }
                
                $0.addTask { await ContextProvider.updateUserContext() }
                $0.addTask { await WidgetManager.setupObservers() }
            }
        }
    }
    
    static func updateUIHook() {
        PersistenceManager.shared.download.scheduleUpdateTask()
        RFNotification[.invalidateProgressEntities].dispatch(payload: nil)
    }
    
    // MARK: Actions
    
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
    
    nonisolated static func invalidateShortTermCache() async {
        logger.info("Invalidating short term cache...")
        
        await ResolveCache.shared.invalidate()
        
        await ProgressTrackerCache.shared.invalidate()
        await DownloadTrackerCache.shared.invalidate()
        
        await ListenNowCache.shared.invalidate()
        
        await RFNotification[.downloadStatusChanged].send(payload: nil)
        await RFNotification[.invalidateProgressEntities].send(payload: nil)
    }
    
    static func refreshItem(itemID: ItemIdentifier) async throws {
        await invalidateShortTermCache()
        
        for size in ItemIdentifier.CoverSize.allCases {
            guard let request = await itemID.coverRequest(size: size) else {
                continue
            }
            
            ImagePipeline.shared.cache.removeCachedImage(for: request)
        }
        
        await RFNotification[.reloadImages].send(payload: itemID)
        await RFNotification[.downloadStatusChanged].send(payload: nil)
        
        try await PersistenceManager.shared.refreshItem(itemID: itemID)
    }
    
    static func invalidateCache() async throws {
        ImagePipeline.shared.cache.removeAll()
        await RFNotification[.reloadImages].send(payload: nil)
        
        try await PersistenceManager.shared.invalidateCache()
    }
}

private extension ShelfPlayer {
    static func writeLogEntitiesToFile(_ entities: AnySequence<OSLogEntry>, at url: URL) throws {
        try entities.map {
            "\($0.date.formatted(.iso8601)): \($0.composedMessage)"
        }.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }
}
