//
//  OpenIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct OpenIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.open.title"
    public static let description = IntentDescription("intent.open.description")

    public static let openAppWhenRun: Bool = true

    @Parameter(title: "intent.open.parameter.item.title",
               description: "intent.open.parameter.item.description",
               requestValueDialog: IntentDialog("intent.open.parameter.item.dialog"))
    public var item: ItemEntity

    public init() {}

    public init(item: Item) async {
        self.item = await .init(item: item)
    }

    public init(item: ItemEntity) {
        self.item = item
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("intent.open.summary \(\.$item)")
    }

    @MainActor
    public func perform() async throws -> some ReturnsValue<ItemEntity> {
        item.id.navigateIsolated()
        return .result(value: item)
    }
}
