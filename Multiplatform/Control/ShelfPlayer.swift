//
//  ShelfPlayer.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.03.25.
//

import Foundation
import OSLog
import TipKit
import Nuke
import ShelfPlayerKit

struct ShelfPlayer {
    static let logger = Logger(subsystem: "io.rfk.ShelfPlayer", category: "Hooks")
    
    static func launchHook() {
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        
        do {
            try Tips.configure()
        } catch {
            logger.error("Failed to configure tips: \(error)")
        }
    }
    
    static func initializeHook() {
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
    
    static func clearCache() {
        ImagePipeline.shared.cache.removeAll()
    }
}
