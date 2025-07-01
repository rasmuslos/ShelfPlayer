//
//  OpenIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import AppIntents

public struct OpenIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.open"
    public static let description = IntentDescription("intent.open.description")
    
    public static let openAppWhenRun: Bool = true
    
    @Parameter(title: "intent.entity.item", description: "intent.entity.item.description")
    public var item: ItemEntity
    
    public init() {}
    
    public init(item: Item) async {
        self.item = await .init(item: item)
    }
    public init(item: ItemEntity) {
        self.item = item
    }
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.open \(\.$item)")
    }
    
    @MainActor
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        item.id.navigateIsolated()
        return .result(value: item)
    }
}
