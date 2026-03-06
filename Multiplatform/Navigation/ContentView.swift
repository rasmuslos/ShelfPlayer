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
import OSLog
import ShelfPlayback

struct ContentView: View {
    let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "ContentView")
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    
    @Namespace private var namespace
    
    @Default(.tintColor) private var tintColor
    @Default(.colorScheme) private var colorScheme
    
    @State private var satellite = Satellite.shared
    @State private var offlineMode = OfflineMode.shared
    
    @State private var connectionStore = ConnectionStore.shared
    @State private var playbackViewModel = PlaybackViewModel.shared
    
    @State private var itemNavigationController = ItemNavigationController()
    
    @ViewBuilder
    private func applyEnvironment<Content: View>(_ content: Content) -> some View {
        content
            .environment(offlineMode)
            .environment(connectionStore)
            .environment(satellite)
            .environment(playbackViewModel)
            .environment(itemNavigationController)
            .environment(\.namespace, namespace)
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: Satellite.Sheet) -> some View {
        switch sheet {
            case .listenNow:
                ListenNowSheet()
                    .navigationTransition(.zoom(sourceID: "listen-now-sheet", in: namespace))
            case .preferences:
                PreferencesView()
            case .debugPreferences:
                DebugPreferences()
            case .customTabValuePreferences:
                CustomTabValueSheet()
            case .description(let item):
                DescriptionSheet(item: item)
            case .configureGrouping(let itemID):
                GroupingConfigurationSheet(itemID: itemID)
                    .navigationTransition(.zoom(sourceID: "configure-grouping", in: namespace))
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
            case .customizeLibrary(let library, let scope):
                CustomizeLibraryPanelSheet(library: library, scope: scope)
            case .whatsNew:
                WhatsNewSheet()
            #if DEBUG
            case .debug:
                DebugSheet()
            #endif
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
        ZStack {
            if !connectionStore.didLoad {
                LoadingView()
            } else if connectionStore.connections.isEmpty {
                WelcomeView()
            } else if offlineMode.isEnabled {
                OfflineView()
            } else {
                TabRouter()
            }
        }
        .modify(if: tintColor != .shelfPlayer) {
            $0
                .tint(tintColor.color)
        }
        .modify(if: colorScheme != .system) {
            $0
                .preferredColorScheme(colorScheme == .light ? .light : .dark)
        }
        .hapticFeedback(.error, trigger: satellite.notifyError)
        .hapticFeedback(.success, trigger: satellite.notifySuccess)
        .hapticFeedback(.error, trigger: PlaybackViewModel.shared.notifyError)
        .hapticFeedback(.success, trigger: PlaybackViewModel.shared.notifySuccess)
        .modifier(PlaybackContentModifier())
        .sheet(item: satellite.presentedSheet) {
            sheetContent(for: $0)
                .modify(if: ProcessInfo.processInfo.isiOSAppOnMac) {
                    applyEnvironment($0)
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
            logger.info("ContentView::onAppear")
            ShelfPlayer.initializeUIHook()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                logger.info("Scene is now active")
                RFNotification[.scenePhaseDidChange].send(payload: true)
                
                Task {
                    await ShelfPlayer.invalidateShortTermCache()
                }
            } else {
                logger.info("Scene is now inactive")
                RFNotification[.scenePhaseDidChange].send(payload: false)
            }
        }
        .onContinueUserActivity(CSQueryContinuationActionType) {
            guard let query = $0.userInfo?[CSSearchQueryString] as? String else {
                logger.warning("Received a malformed query to set the global search from Spotlight")
                return
            }
            
            logger.info("Setting global search to: \(query) from Spotlight")
            
            Task {
                try await Task.sleep(for: .seconds(0.6))
                await RFNotification[.setGlobalSearch].send(payload: (query, .global))
            }
        }
        .onContinueUserActivity("io.rfk.shelfPlayer.item") { activity in
            guard let identifier = activity.persistentIdentifier else {
                logger.info("Spotlight activity did not contain a valid persistent identifier")
                return
            }
            
            logger.info("Received a Spotlight activity for item with identifier: \(identifier)")
            
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
