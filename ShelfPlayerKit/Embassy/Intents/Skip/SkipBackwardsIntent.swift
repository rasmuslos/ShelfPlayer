//
//  SkipBackwardsIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.06.25.
//

import Foundation
import AppIntents

public struct SkipBackwardsIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.skip.backwards"
    public static let description = IntentDescription("intent.skip.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    @Parameter(title: "intent.skip.interval", controlStyle: .field, inclusiveRange: (0, 108_000))
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
