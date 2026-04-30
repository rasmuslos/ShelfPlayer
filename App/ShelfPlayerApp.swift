//
//  ShelfPlayerApp.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import AppIntents
import ShelfPlayback

@main
struct ShelfPlayerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        let environment = ProcessInfo.processInfo.environment

        #if DEBUG
        // UI-testing hook: wipe keychain credentials before any subsystem
        // (ConnectionStore, AuthorizationSubsystem) can read stale state. Must
        // run before launchHook for the same reason. Debug-only so the wipe
        // can never ship in a release binary.
        if environment["WIPE_CONNECTIONS"] == "YES" {
            PersistenceManager.AuthorizationSubsystem.debugWipeAllConnections()
        }
        #endif

        ShelfPlayer.launchHook()

        Task {
            #if DEBUG
            if environment["FORCE_OFFLINE_MODE"] == "YES" {
                // Wait for the initial connection probe to finish; otherwise the
                // `connectionsChanged` event that fires once the keychain finishes
                // loading triggers a refreshAvailability that resets forcedEnabled.
                await OfflineMode.shared.ensureAvailabilityEstablished(reason: "FORCE_OFFLINE_MODE launch argument")
                OfflineMode.shared.forceEnable(reason: "FORCE_OFFLINE_MODE launch argument")
            }
            #endif

            if let itemIDDescription = environment["NAVIGATE_TO_ITEM_IDENTIFIER"] {
                await ItemIdentifier(itemIDDescription).navigate()
            }

            if environment["RUN_CONVENIENCE_DOWNLOAD"] == "YES" {
                await PersistenceManager.shared.convenienceDownload.scheduleAll()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ShelfPlayerPackage: AppIntentsPackage {
    static let includedPackages: [any AppIntentsPackage.Type] = [
        ShelfPlayerKitPackage.self,
    ]
}
