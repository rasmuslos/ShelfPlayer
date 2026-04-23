//
//  SearchIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct SearchIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.search"
    public static let description = IntentDescription("intent.search.description")

    @Parameter(title: "intent.search.query",
               requestValueDialog: IntentDialog("What would you like to search for?"))
    public var search: String

    @Parameter(title: "intent.search.includeOnlineSearchResults",
               description: "intent.search.includeOnlineSearchResults.description",
               default: true,
               requestValueDialog: IntentDialog("Include online results?"))
    public var includeOnlineSearchResults: Bool

    public init() {}

    public static var parameterSummary: some ParameterSummary {
        Summary("intent.search \(\.$search)")
    }

    public func perform() async throws -> some ReturnsValue<[ItemEntity]> {
        try await .result(value: ItemEntityQuery.entities(matching: search, includeSuggestedEntities: includeOnlineSearchResults))
    }
}
