//
//  ShortcutProvider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import AppIntents

public struct ShortcutProvider: AppShortcutsProvider {
    public static var shortcutTileColor: ShortcutTileColor {
        .yellow
    }
    
    @AppShortcutsBuilder
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartIntent(), phrases: [
            "Play \(\.$item) using \(.applicationName)",
        ], shortTitle: "intent.start", systemImageName: "play.square")
        
        AppShortcut(intent: StartAudiobookIntent(), phrases: [
            "Play \(\.$target) using \(.applicationName)",
        ], shortTitle: "intent.start.audiobook", systemImageName: "bookmark.square")
        
        AppShortcut(intent: StartPodcastIntent(), phrases: [
            "Play \(\.$podcast) using \(.applicationName)",
            "Play \(\.$podcast) episodes using \(.applicationName)",
        ], shortTitle: "intent.start.podcast", systemImageName: "play.square.stack")
        
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
        
        AppShortcut(intent: CreateBookmarkIntent(), phrases: [
            "Create a bookmark using \(.applicationName)",
        ], shortTitle: "intent.createBookmark", systemImageName: "bookmark")
        
        AppShortcut(intent: SkipBackwardsIntent(), phrases: [
            "Backwards using \(.applicationName)",
            "Skip backwards using \(.applicationName)",
        ], shortTitle: "intent.skip.backwards", systemImageName: "arrow.trianglehead.counterclockwise.rotate.90")
        AppShortcut(intent: SkipForwardsIntent(), phrases: [
            "Forwards using \(.applicationName)",
            "Skip forwards using \(.applicationName)",
        ], shortTitle: "intent.skip.forwards", systemImageName: "arrow.trianglehead.clockwise.rotate.90")
        
        AppShortcut(intent: CheckForDownloadsIntent(), phrases: [
            "Search for new downloads using \(.applicationName)",
            "Check for new downloads using \(.applicationName)",
        ], shortTitle: "intent.checkForDownloads", systemImageName: "arrow.down")
    }
}
