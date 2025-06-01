//
//  StartIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Foundation
import AppIntents

public struct StartIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.start"
    public static let description = IntentDescription("intent.start.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    @Parameter(title: "intent.entity.item", description: "intent.entity.item.description")
    public var item: ItemEntity
    
    @Parameter(title: "intent.start.withoutPlaybackSession", description: "intent.start.withoutPlaybackSession.description", default: false)
    public var withoutPlaybackSession: Bool
    
    public init() {}
    public init(item: Item) {
        self.item = .init(item: item)
    }
    public init(item: Item) async {
        self.item = await .init(item: item)
    }
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.entity.item \(\.$item)")
    }
    
    public func perform() async throws -> some IntentResult {
        switch item.id.type {
            case .audiobook, .episode:
                try await audioPlayer.start(item.id, withoutPlaybackSession)
            case .podcast:
                guard let episode = try await ResolvedUpNextStrategy.podcast(item.id).resolve(cutoff: nil).first else {
                    throw IntentError.notFound
                }
                
                try await audioPlayer.start(episode.id, withoutPlaybackSession)
            default:
                throw IntentError.invalidItemType
        }
        
        return .result()
    }
}
