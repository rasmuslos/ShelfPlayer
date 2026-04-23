//
//  SkipForwardsIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct SkipForwardsIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.skipForwards.title"
    public static let description = IntentDescription("intent.skipForwards.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    @Parameter(title: "intent.skipForwards.parameter.interval.title",
               controlStyle: .field,
               inclusiveRange: (0, 108_000),
               requestValueDialog: IntentDialog("intent.skipForwards.parameter.interval.dialog"))
    public var interval: TimeInterval?

    public init() {}

    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }

        try await audioPlayer.skip(interval, forwards: true)

        return .result()
    }
}
