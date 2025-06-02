//
//  ShortcutProvider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
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
        AppShortcut(intent: StartIntent(), phrases: [
            "Play an item using \(.applicationName)",
            "Play an audiobook using \(.applicationName)",
            "Play an episode using \(.applicationName)",
            "Play an podcast using \(.applicationName)",
            "Play \(\.$item) using \(.applicationName)",
        ], shortTitle: "intent.start", systemImageName: "play.square")
        
        AppShortcut(intent: PlayIntent(), phrases: [
            "Resume \(.applicationName)",
            "Resume playback with \(.applicationName)",
            "Continue playing \(.applicationName)",
        ], shortTitle: "intent.play", systemImageName: "play.fill")
        AppShortcut(intent: PauseIntent(), phrases: [
            "Pause \(.applicationName)",
            "Pause \(.applicationName) playback",
            "Stop playing \(.applicationName)",
        ], shortTitle: "intent.pause", systemImageName: "pause.fill")
    }
}
