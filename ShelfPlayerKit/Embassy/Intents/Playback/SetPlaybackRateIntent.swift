//
//  SetPlaybackRateIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct SetPlaybackRateIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.setPlaybackRate.title"
    public static let description = IntentDescription("intent.setPlaybackRate.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    @Parameter(title: "intent.setPlaybackRate.parameter.rate.title",
               controlStyle: .stepper,
               inclusiveRange: (1, 800),
               requestValueDialog: IntentDialog("intent.setPlaybackRate.parameter.rate.dialog"))
    public var rate: Percentage

    public init() {}

    public init(rate: Percentage) {
        self.rate = rate
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("intent.setPlaybackRate.summary \(\.$rate)")
    }

    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }

        await audioPlayer.setPlaybackRate(rate / 100)

        return .result()
    }
}
