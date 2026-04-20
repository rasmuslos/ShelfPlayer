//
//  CancelSleepTimerIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct CancelSleepTimerIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.cancelSleepTimer"
    public static let description = IntentDescription("intent.cancelSleepTimer.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    public init() {}

    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }

        await audioPlayer.setSleepTimer(nil)

        return .result()
    }
}
