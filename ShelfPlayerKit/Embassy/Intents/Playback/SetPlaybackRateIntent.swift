//
//  SetPlaybackRateIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.06.25.
//

import Foundation
import AppIntents


public struct SetPlaybackRateIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.setPlaybackRate"
    public static let description = IntentDescription("intent.setPlaybackRate.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    @Parameter(title: "intent.setPlaybackRate.rate", controlStyle: .stepper, inclusiveRange: (1, 800))
    public var rate: Percentage
    
    public init() {}
    public init(rate: Percentage) {
        self.rate = rate
    }
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.setPlaybackRate \(\.$rate)")
    }
    
    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }
        
        await audioPlayer.setPlaybackRate(rate / 100)
        
        return .result()
    }
}
