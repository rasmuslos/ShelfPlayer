//
//  AudiobooksApp.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import Nuke
import ShelfPlayerKit

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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
