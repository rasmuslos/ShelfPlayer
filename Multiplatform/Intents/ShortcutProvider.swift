//
//  ShortcutProvider.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.11.24.
//

import Foundation
import AppIntents

struct ShortcutProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CheckForNewDownloadsIntent(), phrases: [
            "Update episodes in \(.applicationName))",
            "Update downloads in \(.applicationName))",
            "Check for new episodes in \(.applicationName))",
            "Check for new downloads in \(.applicationName))",
        ], shortTitle: "intents.checkForNewDownloads.title", systemImageName: "antenna.radiowaves.left.and.right")
    }
    
    static var shortcutTileColor: ShortcutTileColor = .yellow
}
