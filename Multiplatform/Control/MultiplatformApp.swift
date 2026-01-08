//
//  AudiobooksApp.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import AppIntents
import ShelfPlayback

@main
struct MultiplatformApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if !ENABLE_CENTRALIZED
        ShelfPlayerKit.enableCentralized = false
        #endif
        
        ShelfPlayer.launchHook()
        
        let environment = ProcessInfo.processInfo.environment
        
        Task {
            if let itemIDDescription = environment["NAVIGATE_TO_ITEM_IDENTIFIER"] {
                await ItemIdentifier(itemIDDescription).navigate()
            }
            
            if environment["RUN_CONVENIENCE_DOWNLOAD"] == "YES" {
                await PersistenceManager.shared.convenienceDownload.scheduleAll()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ShelfPlayerPackage: AppIntentsPackage {
    nonisolated(unsafe) static let includedPackages: [any AppIntentsPackage.Type] = [
        ShelfPlayerKitPackage.self,
    ]
}
