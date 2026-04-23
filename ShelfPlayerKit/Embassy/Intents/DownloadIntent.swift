//
//  DownloadIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct DownloadIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.download.title"
    public static let description = IntentDescription("intent.download.description")

    @Parameter(title: "intent.download.parameter.item.title",
               description: "intent.download.parameter.item.description",
               requestValueDialog: IntentDialog("intent.download.parameter.item.dialog"))
    public var item: ItemEntity

    public init() {}

    @MainActor
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        try await PersistenceManager.shared.download.download(item.id)
        return .result(value: item)
    }
}
