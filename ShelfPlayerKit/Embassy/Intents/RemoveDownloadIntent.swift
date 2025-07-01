//
//  DownloadIntent 2.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.07.25.
//

import Foundation
import AppIntents

public struct RemoveDownloadIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.removeDownload"
    public static let description = IntentDescription("intent.removeDownload.description")
    
    @Parameter(title: "intent.entity.item", description: "intent.entity.item.description")
    public var item: ItemEntity
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        try await PersistenceManager.shared.download.remove(item.id)
        return .result(value: item)
    }
}
