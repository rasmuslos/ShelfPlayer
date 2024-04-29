//
//  AudiobooksApp.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import SPBase
import Nuke
import TipKit

@main
struct MultiplatformApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if !ENABLE_ALL_FEATURES
        ENABLE_ALL_FEATURES = false
        #endif
        
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        BackgroundTaskHandler.setup()
        
        try? Tips.configure([
            .displayFrequency(.daily)
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
