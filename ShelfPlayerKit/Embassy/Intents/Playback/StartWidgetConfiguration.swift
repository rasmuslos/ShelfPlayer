//
//  PlayWidgetConfiguration.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.10.25.
//

import AppIntents
import WidgetKit

public struct StartWidgetConfiguration: WidgetConfigurationIntent, PredictableIntent {
    public static let title: LocalizedStringResource = "intent.start"
    public static let description: IntentDescription = "intent.start.description"
    
    @Parameter(title: "intent.entity.item", description: "intent.entity.item.description")
    public var item: ItemEntity?
    
    public init() {}
    public init(item: Item) async {
        self.item = await ItemEntity(item: item)
    }
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.start \(\.$item)")
    }
    
    public static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: \.$item) {
            $0?.displayRepresentation ?? DisplayRepresentation(title: "intent.start", subtitle: "intent.start.description")
        }
    }
}
