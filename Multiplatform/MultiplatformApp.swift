//
//  AudiobooksApp.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import Nuke
import TipKit
import ShelfPlayerKit

@main
struct MultiplatformApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if !ENABLE_CENTRALIZED
        ShelfPlayerKit.enableCentralized = false
        #endif
        
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        
        // BackgroundTaskHandler.setup()
        // OfflineManager.shared.setupFinishedRemoveObserver()
        
        try? Tips.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
