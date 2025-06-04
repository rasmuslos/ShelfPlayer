//
//  StartIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Foundation
import AppIntents

public struct StartIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.start"
    public static let description = IntentDescription("intent.start.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    @Parameter(title: "intent.entity.item", description: "intent.entity.item.description")
    public var item: ItemEntity
    
    @Parameter(title: "intent.start.withoutPlaybackSession", description: "intent.start.withoutPlaybackSession.description", default: false)
    public var withoutPlaybackSession: Bool
    
    public init() {}
    
    public init(item: Item) async {
        self.item = await .init(item: item)
    }
    public init(item: ItemEntity) {
        self.item = item
    }
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.start \(\.$item)")
    }
    
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        let itemID: ItemIdentifier
        
        switch item.id.type {
            case .audiobook, .episode:
                itemID = item.id
                try await audioPlayer.start(itemID, withoutPlaybackSession)
            case .series, .podcast:
                itemID = try await audioPlayer.startGrouping(item.id, withoutPlaybackSession)
            default:
                throw IntentError.invalidItemType
        }
        
        let entity = try await ItemEntity(item: itemID.resolved)
        
        return .result(value: entity)
    }
}
