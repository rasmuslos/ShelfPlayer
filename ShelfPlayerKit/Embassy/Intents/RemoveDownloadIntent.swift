//
//  RemoveDownloadIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct RemoveDownloadIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.removeDownload.title"
    public static let description = IntentDescription("intent.removeDownload.description")

    @Parameter(title: "intent.removeDownload.parameter.item.title",
               description: "intent.removeDownload.parameter.item.description",
               requestValueDialog: IntentDialog("intent.removeDownload.parameter.item.dialog"))
    public var item: ItemEntity

    public init() {}

    @MainActor
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        try await PersistenceManager.shared.download.remove(item.id)
        return .result(value: item)
    }
}
