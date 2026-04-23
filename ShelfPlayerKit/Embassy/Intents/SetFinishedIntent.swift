//
//  SetFinishedIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct SetFinishedIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.setFinished.title"
    public static let description = IntentDescription("intent.setFinished.description")

    @Parameter(title: "intent.setFinished.parameter.item.title",
               description: "intent.setFinished.parameter.item.description",
               requestValueDialog: IntentDialog("intent.setFinished.parameter.item.dialog"))
    public var item: ItemEntity

    @Parameter(title: "intent.setFinished.parameter.finished.title",
               requestValueDialog: IntentDialog("intent.setFinished.parameter.finished.dialog"))
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
