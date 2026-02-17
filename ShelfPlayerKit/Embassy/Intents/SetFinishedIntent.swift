//
//  SetFinishedIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.07.25.
//

import Foundation
import AppIntents

public struct SetFinishedIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.setFinished"
    public static let description = IntentDescription("intent.setFinished.description")
    
    @Parameter(title: "intent.entity.item", description: "intent.entity.item.description")
    public var item: ItemEntity
    
    @Parameter(title: "intent.setFinished.finished")
    public var finished: Bool
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        if finished {
            try await PersistenceManager.shared.progress.markAsCompleted(item.id)
        } else {
            try await PersistenceManager.shared.progress.markAsListening(item.id)
        }
        
        return .result(value: item)
    }
}

