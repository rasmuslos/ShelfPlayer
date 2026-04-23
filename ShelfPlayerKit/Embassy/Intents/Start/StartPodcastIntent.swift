//
//  StartPodcastIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct StartPodcastIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.startPodcast.title"
    public static let description = IntentDescription("intent.startPodcast.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    public init() {}

    public init(podcast: Podcast) async {
        self.podcast = await .init(podcast: podcast)
    }

    @Parameter(title: "intent.startPodcast.parameter.podcast.title",
               description: "intent.startPodcast.parameter.podcast.description",
               requestValueDialog: IntentDialog("intent.startPodcast.parameter.podcast.dialog"),
               optionsProvider: PodcastEntityOptionsProvider())
    public var podcast: PodcastEntity

    public static var parameterSummary: some ParameterSummary {
        Summary("intent.startPodcast.summary \(\.$podcast)")
    }

    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        let itemID = try await audioPlayer.startGrouping(podcast.id)
        let entity = try await ItemEntity(item: itemID.resolved)

        return .result(value: entity)
    }
}
