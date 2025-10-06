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
    @Default(.colorScheme) private var colorScheme
    
    @State private var satellite = Satellite.shared
    @State private var playbackViewModel = PlaybackViewModel.shared
    
    @State private var connectionStore = ConnectionStore.shared
    @State private var progressViewModel = ProgressViewModel.shared
    
    @State private var listenedTodayTracker = ListenedTodayTracker.shared
    
    @ViewBuilder
    private func applyEnvironment<Content: View>(_ content: Content) -> some View {
        content
            .environment(satellite)
            .environment(playbackViewModel)
            .environment(connectionStore)
            .environment(progressViewModel)
            .environment(listenedTodayTracker)
            .environment(\.namespace, namespace)
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: Satellite.Sheet) -> some View {
        switch sheet {
            case .listenNow:
                ListenNowSheet()
            case .preferences:
                PreferencesView()
            case .description(let item):
                DescriptionSheet(item: item)
            case .configureGrouping(let itemID):
                GroupingConfigurationSheet(itemID: itemID)
            case .editCollection(let collection):
                EditCollectionSheet(collection: collection)
            case .editCollectionMembership(let itemID):
                CollectionMembershipEditorSheet(itemID: itemID)
            case .addConnection:
                ConnectionAddSheet()
            case .editConnection(let connectionID):
                ConnectionEditSheet(connectionID: connectionID)
            case .reauthorizeConnection(let connectionID):
                ReauthorizeConnectionSheet(connectionID: connectionID)
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
            case .acknowledge:
                Button("action.acknowledge") {
                    satellite.confirmWarningAlert()
                }
                
            case .dismiss:
                Button("action.dismiss") {
                    satellite.cancelWarningAlert()
                }
                
            case .learnMore(let url):
                Link(destination: url) {
                    Text("action.learnMore")
                }
            case .removeConvenienceDownloadConfigurations(let itemID):
                Button("item.convenienceDownload.remove") {
                    satellite.removeConvenienceDownloadConfigurations(from: itemID)
                }
        }
    }
    
    var body: some View {
        Group {
            if !ConnectionStore.shared.didLoad {
                LoadingView()
            } else if ConnectionStore.shared.connections.isEmpty {
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
        .modify {
            if colorScheme != .system {
                $0
                    .preferredColorScheme(colorScheme == .light ? .light : .dark)
            } else {
                $0
            }
        }
        .sensoryFeedback(.error, trigger: satellite.notifyError)
        .sensoryFeedback(.success, trigger: satellite.notifySuccess)
        .sensoryFeedback(.error, trigger: PlaybackViewModel.shared.notifyError)
        .sensoryFeedback(.success, trigger: PlaybackViewModel.shared.notifySuccess)
        .modifier(PlaybackContentModifier())
        .sheet(item: satellite.presentedSheet) {
            sheetContent(for: $0)
                .modify {
                    if ProcessInfo.processInfo.isiOSAppOnMac {
                        applyEnvironment($0)
                    } else {
                        $0
                    }
                }
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
        .modify {
            applyEnvironment($0)
        }
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
            
            Task {
                try await Task.sleep(for: .seconds(0.6))
                await RFNotification[.setGlobalSearch].send(payload: (query, .global))
            }
        }
        .onContinueUserActivity("io.rfk.shelfPlayer.item") { activity in
            guard let identifier = activity.persistentIdentifier else {
                return
            }
            
            Task {
                try await Task.sleep(for: .seconds(0.6))
                await ItemIdentifier(identifier).navigate()
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var namespace: Namespace.ID?
}

#Preview {
    ContentView()
}
