//
//  NowPlayingIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import AppIntents

public struct NowPlayingIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.nowPlaying"
    public static let description = IntentDescription("intent.nowPlaying.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.nowPlaying")
    }
    
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        guard let currentItemID = await audioPlayer.currentItemID else {
            throw IntentError.noPlaybackItem
        }
        
        return try await .result(value: ItemEntity(item: currentItemID.resolved))
    }
}
