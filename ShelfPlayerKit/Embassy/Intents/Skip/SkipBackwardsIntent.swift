//
//  SkipBackwardsIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct SkipBackwardsIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.skipBackwards.title"
    public static let description = IntentDescription("intent.skipBackwards.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    @Parameter(title: "intent.skipBackwards.parameter.interval.title",
               controlStyle: .field,
               inclusiveRange: (0, 108_000),
               requestValueDialog: IntentDialog("intent.skipBackwards.parameter.interval.dialog"))
    public var interval: TimeInterval?

    public init() {}

    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }

        try await audioPlayer.skip(interval, forwards: false)

        return .result()
    }
}
