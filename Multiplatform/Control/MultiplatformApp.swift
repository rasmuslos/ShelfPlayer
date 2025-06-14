//
//  AudiobooksApp.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import ShelfPlayback

@main
struct MultiplatformApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if !ENABLE_CENTRALIZED
        ShelfPlayerKit.enableCentralized = false
        #endif
        
        if ProcessInfo.processInfo.environment["LISTEN_NOW_DOWNLOADS_DISABLE"] == "YES" {
            Defaults[.enableListenNowDownloads] = false
        }
        
        ShelfPlayer.launchHook()
        
        if ProcessInfo.processInfo.environment["RUN_CONVENIENCE_DOWNLOAD"] == "YES" {
            Task {
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
