//
//  StartWidgetConfiguration.swift
//  ShelfPlayerKit
//

import AppIntents
import WidgetKit

public struct StartWidgetConfiguration: WidgetConfigurationIntent, PredictableIntent {
    public static let title: LocalizedStringResource = "intent.startWidget.title"
    public static let description: IntentDescription = "intent.startWidget.description"

    @Parameter(title: "intent.startWidget.parameter.item.title", description: "intent.startWidget.parameter.item.description")
    public var item: ItemEntity?

    public init() {}

    public init(item: Item) async {
        self.item = await ItemEntity(item: item)
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("intent.startWidget.summary \(\.$item)")
    }

    public static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: \.$item) {
            $0?.displayRepresentation ?? DisplayRepresentation(title: "intent.startWidget.title", subtitle: "intent.startWidget.description")
        }
    }
}
