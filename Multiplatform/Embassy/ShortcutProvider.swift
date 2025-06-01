//
//  ShortcutProvider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import Defaults
import AppIntents
import ShelfPlayback

struct ShelfPlayerPackage: AppIntentsPackage {
    static let includedPackages: [any AppIntentsPackage.Type] = [
        ShelfPlayerKitPackage.self,
    ]
}

struct ShortcutProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor {
        .yellow
    }
    @AppShortcutsBuilder static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: PlayIntent(), phrases: [
            "Resume \(.applicationName)",
            "Resume playback with \(.applicationName)",
            "Continue playing \(.applicationName)",
            
            "Spiele \(.applicationName) weiter",
            "Setzte die Wiedergabe mit \(.applicationName) fort",
        ], shortTitle: "intent.play", systemImageName: "play.fill")
        AppShortcut(intent: PauseIntent(), phrases: [
            "Pause \(.applicationName)",
            "Pause \(.applicationName) playback",
            "Stop playing \(.applicationName)",
            
            "Pausiere \(.applicationName)",
            "Pausiere die Wiedergabe mit \(.applicationName)",
        ], shortTitle: "intent.pause", systemImageName: "pause.fill")
    }
}
