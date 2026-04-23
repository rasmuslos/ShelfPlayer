//
//  StartIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct StartIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.start"
    public static let description = IntentDescription("intent.start.description")

    @AppDependency private var audioPlayer: IntentAudioPlayer

    @Parameter(title: "intent.entity.item",
               description: "intent.entity.item.description",
               requestValueDialog: IntentDialog("What would you like to play?"),
               optionsProvider: ItemEntityOptionsProvider())
    public var item: ItemEntity

    public init() {}

    public init(item: Item) async {
        self.item = await .init(item: item)
    }

    public init(item: ItemEntity) {
        self.item = item
    }

    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        let itemID: ItemIdentifier

        switch item.id.type {
        case .audiobook, .episode:
            itemID = item.id
            try await audioPlayer.start(itemID)
        case .series, .podcast:
            itemID = try await audioPlayer.startGrouping(item.id)
        default:
            throw IntentError.invalidItemType
        }

        let entity = try await ItemEntity(item: itemID.resolved)

        return .result(value: entity)
    }
}
