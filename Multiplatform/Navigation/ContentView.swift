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
import ShelfPlayback

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) var scenePhase
    
    @Namespace private var namespace
    
    @Default(.tintColor) private var tintColor
    
    @State private var satellite = Satellite.shared
    @State private var playbackViewModel = PlaybackViewModel()
    
    @State private var connectionStore = ConnectionStore()
    @State private var progressViewModel = ProgressViewModel()
    
    // try? await UserContext.run()
    // try? await BackgroundTaskHandler.updateDownloads()
    
    @ViewBuilder
    private func sheetContent(for sheet: Satellite.Sheet) -> some View {
        switch sheet {
            case .listenNow:
                ListenNowSheet()
            case .globalSearch:
                GlobalSearchSheet()
            case .preferences:
                PreferencesView()
            case .description(let item):
                DescriptionSheet(item: item)
            case .configureGrouping(let itemID):
                GroupingConfigurationSheet(itemID: itemID)
            case .whatsNew:
                WhatsNewSheet()
        }
    }
    @ViewBuilder
    private func warningButton(for action: Satellite.WarningAlert.WarningAction) -> some View {
        switch action {
            case .cancel:
                Button("action.cancel", role: .cancel) {
                    satellite.cancelWarningAlert()
                }
            case .proceed:
                Button("action.proceed") {
                    satellite.confirmWarningAlert()
                }
            case .dismiss:
                Button("action.dismiss") {
                    satellite.cancelWarningAlert()
                }
                
            case .removeConvenienceDownloadConfigurations(let itemID):
                Button("item.convenienceDownload.remove") {
                    satellite.removeConvenienceDownloadConfigurations(from: itemID)
                }
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
                TabRouter()
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
        }
        .alert(String(), isPresented: satellite.isWarningAlertPresented) {
            ForEach(satellite.warningAlertStack.first?.actions ?? []) {
                warningButton(for: $0)
            }
        } message: {
            if let message = satellite.warningAlertStack.first?.message {
                Text(message)
            }
        }
        .environment(satellite)
        .environment(playbackViewModel)
        .environment(connectionStore)
        .environment(progressViewModel)
        .environment(ListenedTodayTracker.shared)
        .environment(\.namespace, namespace)
        .onAppear {
            ShelfPlayer.initializeUIHook()
        }
        .onChange(of: scenePhase) {
            Task.detached { [scenePhase] in
                switch scenePhase {
                    case .active:
                        await RFNotification[.performBackgroundSessionSync].send(payload: nil)
                        await ShelfPlayer.invalidateShortTermCache()
                        
                        await RFNotification[.scenePhaseDidChange].send(payload: true)
                    case .inactive:
                        await RFNotification[.scenePhaseDidChange].send(payload: false)
                    default:
                        break
                }
            }
        }
        .onContinueUserActivity(CSQueryContinuationActionType) {
            guard let query = $0.userInfo?[CSSearchQueryString] as? String else {
                return
            }
            
            satellite.present(.globalSearch)
            
            Task {
                try await Task.sleep(for: .seconds(0.4))
                await RFNotification[.setGlobalSearch].send(payload: query)
            }
        }
        .onContinueUserActivity("io.rfk.shelfPlayer.item") { activity in
            guard let identifier = activity.persistentIdentifier else {
                return
            }
            
            ItemIdentifier(identifier).navigate()
        }
    }
}

extension EnvironmentValues {
    @Entry var namespace: Namespace.ID?
}

#Preview {
    ContentView()
}
