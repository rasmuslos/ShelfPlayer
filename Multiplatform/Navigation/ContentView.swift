//
//  ContentView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import Intents
import CoreSpotlight
import SwiftData
import Defaults
import RFNotifications
import ShelfPlayerKit

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.tintColor) private var tintColor
    @Default(.lastTabValue) private var lastTabValue
    
    @State private var isOffline = false
    @State private var connectionStore = ConnectionStore()
    
    // try? await OfflineManager.shared.attemptListeningTimeSync()
    // try? await UserContext.run()
    // try? await BackgroundTaskHandler.updateDownloads()
    
    var body: some View {
        Group {
            if !connectionStore.didLoad {
                LoadingView()
            } else if connectionStore.flat.isEmpty {
                WelcomeView()
            } else if isOffline {
                
            } else {
                TabRouter(selection: $lastTabValue)
            }
        }
        .tint(tintColor.color)
        .onReceive(RFNotification[.changeOfflineMode].publisher()) {
            isOffline = $0
        }
        .onContinueUserActivity(CSSearchableItemActionType) {
            guard let identifier = $0.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return
            }
            
            ""
        }
        .onContinueUserActivity("io.rfk.shelfPlayer.item") { activity in
            guard let identifier = activity.persistentIdentifier else {
                return
            }
            
            ""
        }
        .environment(connectionStore)
    }
}

#Preview {
    ContentView()
}
