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
        
        if ProcessInfo.processInfo.environment["RUN_SPOTLIGHT_INDEX"] == "YES" {
            SpotlightIndexer.shared.run()
        }
        
        AppDependencyManager.shared.add(dependency: PersistenceManager.shared)
        AppDependencyManager.shared.add(dependency: EmbassyManager.shared.intentAudioPlayer)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
