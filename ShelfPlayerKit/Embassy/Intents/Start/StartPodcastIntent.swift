//
//  StartPodcastIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.06.25.
//

import Foundation
import AppIntents

public struct StartPodcastIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.start.podcast"
    public static let description = IntentDescription("intent.start.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public init() {}
    public init(podcast: Podcast) async {
        self.podcast = await .init(podcast: podcast)
    }
    
    @Parameter(title: "intent.entity.item.podcast", description: "intent.entity.item.description", optionsProvider: PodcastEntityOptionsProvider())
    public var podcast: PodcastEntity
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.start.podcast \(\.$podcast)")
    }
    
    public func perform() async throws -> some IntentResult {
        try await audioPlayer.start(podcast.id, false)
        return .result()
    }
}
