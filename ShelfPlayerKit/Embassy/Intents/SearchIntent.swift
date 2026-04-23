//
//  SearchIntent.swift
//  ShelfPlayerKit
//

import Foundation
import AppIntents

public struct SearchIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.search.title"
    public static let description = IntentDescription("intent.search.description")

    @Parameter(title: "intent.search.parameter.search.title",
               requestValueDialog: IntentDialog("intent.search.parameter.search.dialog"))
    public var search: String

    @Parameter(title: "intent.search.parameter.includeOnlineSearchResults.title",
               description: "intent.search.parameter.includeOnlineSearchResults.description",
               default: true,
               requestValueDialog: IntentDialog("intent.search.parameter.includeOnlineSearchResults.dialog"))
    public var includeOnlineSearchResults: Bool

    public init() {}

    public static var parameterSummary: some ParameterSummary {
        Summary("intent.search.summary \(\.$search)")
    }

    public func perform() async throws -> some ReturnsValue<[ItemEntity]> {
        try await .result(value: ItemEntityQuery.entities(matching: search, includeSuggestedEntities: includeOnlineSearchResults))
    }
}
