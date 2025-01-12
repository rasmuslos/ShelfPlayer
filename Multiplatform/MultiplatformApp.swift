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
    @Namespace private var namespace
    
    init() {
        #if !ENABLE_ALL_FEATURES
        SPKit_ENABLE_ALL_FEATURES = false
        #endif
        
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        
        // BackgroundTaskHandler.setup()
        // OfflineManager.shared.setupFinishedRemoveObserver()
        
        try? Tips.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(NamespaceWrapper(namespace))
        }
    }
}
