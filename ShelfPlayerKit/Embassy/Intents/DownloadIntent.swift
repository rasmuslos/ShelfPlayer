//
//  DownloadIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.07.25.
//

import Foundation
import AppIntents

public struct DownloadIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.download"
    public static let description = IntentDescription("intent.download.description")
    
    @Parameter(title: "intent.entity.item", description: "intent.entity.item.description")
    public var item: ItemEntity
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        try await PersistenceManager.shared.download.download(item.id)
        return .result(value: item)
    }
}
