//
//  SkipBackwardsIntent 2.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.06.25.
//

import Foundation
import AppIntents

public struct SkipForwardsIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.skip.forwards"
    public static let description = IntentDescription("intent.skip.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    // 0s --> 30m
    @Parameter(title: "intent.skip.interval", controlStyle: .field, inclusiveRange: (0, 108_000))
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
