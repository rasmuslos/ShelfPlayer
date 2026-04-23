//
//  ContentView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import Intents
import CoreSpotlight
import SwiftData
import OSLog
import ShelfPlayback
import ShelfPlayerMigration

struct ContentView: View {
    let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "ContentView")

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase

    @Namespace private var namespace

    @State private var satellite = Satellite.shared
    @State private var offlineMode = OfflineMode.shared

    @State private var connectionStore = ConnectionStore.shared
    @State private var playbackViewModel = PlaybackViewModel.shared

    @State private var bookmarkEditor = BookmarkEditor()
    @State private var skipController = SkipController.shared
    @State private var itemNavigationController = ItemNavigationController()

    @State private var migrationState: MigrationManager.State = .notNeeded
    @State private var tintColor: TintColor = AppSettings.shared.tintColor
    @State private var configuredColorScheme: ConfiguredColorScheme = AppSettings.shared.colorScheme

    @ViewBuilder
    private func applyEnvironment<Content: View>(_ content: Content) -> some View {
        content
            .environment(offlineMode)
            .environment(connectionStore)
            .environment(satellite)
            .environment(playbackViewModel)
            .environment(bookmarkEditor)
            .environment(skipController)
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
                SettingsView()
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
            case .customizeHome(let scope, let libraryType):
                NavigationStack {
                    HomeCustomizationView(scope: scope, libraryType: libraryType)
                }
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

    private var isMigrating: Bool {
        switch migrationState {
        case .available, .inProgress, .failed:
            true
        default:
            false
        }
    }

    var body: some View {
        ZStack {
            if isMigrating {
                MigrationView(migrationState: $migrationState)
            } else if !connectionStore.didLoad {
                LoadingView()
            } else if connectionStore.connections.isEmpty {
                WelcomeView()
            } else if offlineMode.isEnabled {
                OfflineView()
            } else {
                TabRouter()
            }
        }
        .hapticFeedback(.error, trigger: satellite.notifyError)
        .hapticFeedback(.success, trigger: satellite.notifySuccess)
        .hapticFeedback(.error, trigger: playbackViewModel.notifyError)
        .hapticFeedback(.success, trigger: playbackViewModel.notifySuccess)
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
        .modify(if: tintColor != .shelfPlayer) {
            $0
                .tint(tintColor.color)
        }
        .modify(if: configuredColorScheme != .system) {
            $0
                .preferredColorScheme(configuredColorScheme == .light ? .light : .dark)
        }
        .onAppear {
            logger.info("ContentView::onAppear")
            ShelfPlayer.initializeUIHook()
        }
        .task {
            let completed = await MigrationManager.shared.wasMigrationCompleted()

            if !completed {
                let detected = await MigrationManager.shared.detectOldInstallation()

                if detected {
                    migrationState = .available
                } else {
                    migrationState = .notNeeded
                }
            } else {
                migrationState = .notNeeded
            }
        }
        .onReceive(AppEventSource.shared.appearanceDidChange) {
            tintColor = AppSettings.shared.tintColor
            configuredColorScheme = AppSettings.shared.colorScheme
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                logger.info("Scene is now active")
                AppEventSource.shared.scenePhaseDidChange.send(true)

                Task {
                    await ShelfPlayer.invalidateShortTermCache()
                }
            } else {
                logger.info("Scene is now inactive")
                AppEventSource.shared.scenePhaseDidChange.send(false)
            }
        }
        .onOpenURL { url in
            URLSchemeHandler.handle(url)
        }
        .onContinueUserActivity(CSQueryContinuationActionType) {
            guard let query = $0.userInfo?[CSSearchQueryString] as? String else {
                logger.warning("Received a malformed query to set the global search from Spotlight")
                return
            }

            logger.info("Setting global search to: \(query) from Spotlight")

            Task {
                try await Task.sleep(for: .seconds(0.6))
                NavigationEventSource.shared.setGlobalSearch.send((query, .global))
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
