//
//  ExtendSleepTimerIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct ExtendSleepTimerIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.extendSleepTimer"
    public static let description = IntentDescription("intent.extendSleepTimer.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    public init() {}

    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }

        await audioPlayer.extendSleepTimer()

        return .result()
    }
}
