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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) var scenePhase
    
    @Namespace private var namespace
    
    @Default(.tintColor) private var tintColor
    
    @State private var satellite = Satellite()
    @State private var playbackViewModel = PlaybackViewModel()
    
    @State private var connectionStore = ConnectionStore()
    
    // try? await UserContext.run()
    // try? await BackgroundTaskHandler.updateDownloads()
    
    @ViewBuilder
    private func sheetContent(for sheet: Satellite.Sheet) -> some View {
        switch sheet {
        case .listenNow:
            ListenNowSheet()
        case .preferences:
            PreferencesView()
        case .description(let item):
            DescriptionSheet(item: item)
        case .podcastConfiguration(let itemID):
            PodcastConfigurationSheet(podcastID: itemID)
        }
    }
    
    var body: some View {
        Group {
            if !connectionStore.didLoad {
                LoadingView()
            } else if connectionStore.flat.isEmpty {
                WelcomeView()
            } else if satellite.isOffline {
                OfflineView()
            } else {
                TabRouter(selection: $satellite.lastTabValue)
            }
        }
        .modify {
            if tintColor == .shelfPlayer {
                $0
            } else {
                $0
                    .tint(tintColor.color)
            }
        }
        .sensoryFeedback(.error, trigger: satellite.notifyError)
        .sensoryFeedback(.success, trigger: satellite.notifySuccess)
        .sensoryFeedback(.error, trigger: playbackViewModel.notifyError)
        .sensoryFeedback(.success, trigger: playbackViewModel.notifySuccess)
        .modifier(PlaybackContentModifier())
        .sheet(item: satellite.presentedSheet) {
            sheetContent(for: $0)
                .interactiveDismissDisabled($0.dismissBehavior.preventInteraction)
        }
        .alert(isPresented: satellite.isWarningAlertPresented, error: satellite.warningAlertStack.first) {
            Button("action.cancel", role: .cancel) {
                satellite.cancelWarningAlert()
            }
            Button("action.proceed") {
                satellite.confirmWarningAlert()
            }
        }
        .environment(satellite)
        .environment(playbackViewModel)
        .environment(connectionStore)
        .environment(\.namespace, namespace)
        .onAppear {
            ShelfPlayer.initializeUIHook()
        }
        .onChange(of: scenePhase) {
            Task.detached { [scenePhase] in
                switch scenePhase {
                case .active:
                    await ShelfPlayer.invalidateShortTermCache()
                default:
                    break
                }
            }
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
            
            let itemID = ItemIdentifier(identifier)
            itemID.navigate()
        }
    }
}

extension EnvironmentValues {
    @Entry var namespace: Namespace.ID?
}

#Preview {
    ContentView()
}
