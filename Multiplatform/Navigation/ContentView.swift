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
import ShelfPlayerKit

struct ContentView: View {
    @Namespace private var namespace
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.tintColor) private var tintColor
    
    @State private var satellite = Satellite()
    @State private var playbackViewModel = PlaybackViewModel()
    
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
            } else if satellite.isOffline {
                NavigationStack {
                    List {
                        ConnectionManager()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button("offline.disable") {
                        satellite.isOffline = false
                    }
                }
            } else {
                TabRouter(selection: $satellite.lastTabValue)
            }
        }
        .tint(tintColor.color)
        .sensoryFeedback(.error, trigger: satellite.notifyError)
        .sensoryFeedback(.success, trigger: satellite.notifySuccess)
        .environment(satellite)
        .environment(playbackViewModel)
        .environment(connectionStore)
        .environment(\.namespace, namespace)
        .onAppear {
            ShelfPlayer.initializeHook()
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
    }
}

extension EnvironmentValues {
    @Entry var namespace: Namespace.ID?
}

#Preview {
    ContentView()
}
