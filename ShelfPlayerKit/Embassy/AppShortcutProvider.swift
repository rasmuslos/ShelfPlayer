//
//  AppShortcutProvider.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct AppShortcutProvider: AppShortcutsProvider {
    public static var shortcutTileColor: ShortcutTileColor {
        .yellow
    }

    @AppShortcutsBuilder
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartAudiobookIntent(), phrases: [
            "Play \(\.$target) using \(.applicationName)",
        ], shortTitle: "Play audiobook", systemImageName: "bookmark.square")
        AppShortcut(intent: StartPodcastIntent(), phrases: [
            "Play \(\.$podcast) using \(.applicationName)",
            "Play \(\.$podcast) episodes using \(.applicationName)",
        ], shortTitle: "Play podcast", systemImageName: "play.square.stack")

        AppShortcut(intent: PlayIntent(), phrases: [
            "Resume \(.applicationName)",
            "Resume playback with \(.applicationName)",
            "Continue playing \(.applicationName)",
        ], shortTitle: "Resume playback", systemImageName: "play.fill")
        AppShortcut(intent: PauseIntent(), phrases: [
            "Pause \(.applicationName)",
            "Pause \(.applicationName) playback",
            "Stop playing \(.applicationName)",
        ], shortTitle: "Pause playback", systemImageName: "pause.fill")

        AppShortcut(intent: CreateBookmarkIntent(), phrases: [
            "Create a bookmark using \(.applicationName)",
        ], shortTitle: "Create bookmark", systemImageName: "bookmark")

        AppShortcut(intent: SkipBackwardsIntent(), phrases: [
            "Backwards using \(.applicationName)",
            "Skip backwards using \(.applicationName)",
        ], shortTitle: "Skip backwards", systemImageName: "arrow.trianglehead.counterclockwise.rotate.90")
        AppShortcut(intent: SkipForwardsIntent(), phrases: [
            "Forwards using \(.applicationName)",
            "Skip forwards using \(.applicationName)",
        ], shortTitle: "Skip forwards", systemImageName: "arrow.trianglehead.clockwise.rotate.90")

        AppShortcut(intent: SetSleepTimerIntent(), phrases: [
            "Set \(.applicationName) sleep timer",
            "Set a sleep timer using \(.applicationName)",
        ], shortTitle: "Set sleep timer", systemImageName: "moon.zzz.fill")
        AppShortcut(intent: SetPlaybackRateIntent(), phrases: [
            "Set \(.applicationName) playback speed",
            "Set \(.applicationName) playback rate",
        ], shortTitle: "Set playback speed", systemImageName: "percent")

        AppShortcut(intent: CheckForDownloadsIntent(), phrases: [
            "Search for new downloads using \(.applicationName)",
            "Check for new downloads using \(.applicationName)",
        ], shortTitle: "Check for new downloads", systemImageName: "arrow.down")
    }
}
