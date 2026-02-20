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
import AppIntents
import BackgroundTasks
import ShelfPlayback

struct ShelfPlayer {
    static let logger = Logger(subsystem: "io.rfk.ShelfPlayer", category: "Hooks")
    
    // MARK: Hooks
    
    static func launchHook() {
        Task {
            await OfflineMode.shared.refreshAvailability()
        }
        
        do {
            try Tips.configure()
        } catch {
            logger.error("Failed to configure tips: \(error)")
        }
        
        // Execute task early:
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"io.rfk.shelfPlayer.spotlightIndex"]
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"io.rfk.shelfPlayer.convenienceDownload"]
        
        print(Thread.isMainThread, Thread.current)
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: SpotlightIndexer.BACKGROUND_TASK_IDENTIFIER, using: .main) { task in
            Task {
                await SpotlightIndexer.shared.handleBackgroundTask(task)
            }
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: PersistenceManager.ConvenienceDownloadSubsystem.BACKGROUND_TASK_IDENTIFIER, using: .main) {
            PersistenceManager.shared.convenienceDownload.handleBackgroundTask($0)
        }
        
        let intentAudioPlayer = EmbassyManager.shared.intentAudioPlayer
        AppDependencyManager.shared.add(dependency: PersistenceManager.shared)
        AppDependencyManager.shared.add(dependency: intentAudioPlayer)
    }
    
    static func initializeUIHook() {
        #if ENABLE_CENTRALIZED
        INPreferences.requestSiriAuthorization {
            logger.info("Got Siri authorization status: \($0.rawValue)")
        }
        #endif
        
        let lastBuild = Defaults[.lastBuild]
        
        // Fresh install
        if lastBuild == nil {
            Defaults[.lastToSUpdate] = ShelfPlayerKit.currentToSVersion
        }
        
        // Invalidate cache after an update
        let clientBuild = ShelfPlayerKit.clientBuild
        if let lastBuild, clientBuild < lastBuild {
            logger.info("ShelfPlayer has been updated. Invalidating cache...")
            
            Task {
                try await ShelfPlayer.invalidateCache()
            }
        }
        
        Defaults[.lastBuild] = clientBuild
        
        // ToS
        let lastToSUpdate = Defaults[.lastToSUpdate] ?? -1
        if lastToSUpdate < ShelfPlayerKit.currentToSVersion {
            Task {
                Satellite.shared.warn(.termsOfServiceChanged)
            }
        }
        
        Task {
            await withTaskGroup {
                $0.addTask { await PersistenceManager.shared.download.invalidateActiveDownloads() }
                $0.addTask { await PersistenceManager.shared.download.scheduleUpdateTask() }
                
                $0.addTask { await EmbassyManager.shared.setupObservers() }
                $0.addTask { await EmbassyManager.shared.endSleepTimerActivity() }
            }
        }
    }
    
    @MainActor
    private static var didOnlineHookRun = false
    static func initOnlineUIHook() {
        Task {
            let logger = Self.logger
            
            guard !didOnlineHookRun else {
                return
            }
            
            didOnlineHookRun = true
            
            Embassy.unsetWidgetIsPlaying()
            AppShortcutProvider.updateAppShortcutParameters()
            
            await withTaskGroup {
                $0.addTask {
                    do {
                        try await PersistenceManager.shared.session.attemptSync(early: false)
                    } catch {
                        logger.error("Failed to sync sessions: \(error)")
                    }
                }
                
                $0.addTask { await ContextProvider.updateUserContext() }
                $0.addTask { await PlayMediaIntentHandler.donateListenNowIntents() }
                
                $0.addTask { await SpotlightIndexer.shared.scheduleBackgroundTask() }
                $0.addTask { await PersistenceManager.shared.convenienceDownload.scheduleBackgroundTask(shouldWait: false) }
            }
        }
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
    
    static func invalidateShortTermCache() async {
        await ABSClient.flushClientCache()
        
        logger.info("Invalidating short term cache...")
        
        await RFNotification[.downloadStatusChanged].send(payload: nil)
        await RFNotification[.invalidateProgressEntities].send(payload: nil)
    }
    
    static func refreshItem(itemID: ItemIdentifier) async throws {
        await ABSClient.flushClientCache()
        
        await invalidateShortTermCache()
        
        await ImageLoader.shared.purge(itemID: itemID)
        await ResolveCache.shared.invalidate(itemID: itemID)
        
        await RFNotification[.reloadImages].send(payload: itemID)
        await RFNotification[.downloadStatusChanged].send(payload: nil)
        
        try await PersistenceManager.shared.refreshItem(itemID: itemID)
    }
    
    static func invalidateCache() async throws {
        await ABSClient.flushClientCache()
        await ResolveCache.shared.flush()
        
        await ImageLoader.shared.purge()
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
