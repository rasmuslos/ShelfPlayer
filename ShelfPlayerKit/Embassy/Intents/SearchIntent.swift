//
//  SearchIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import AppIntents

public struct SearchIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.search"
    public static let description = IntentDescription("intent.search.description")
    
    @Parameter(title: "intent.search.query", description: "intent.search.query.description")
    public var search: String
    
    @Parameter(title: "intent.search.includeOnlineSearchResults", description: "intent.search.includeOnlineSearchResults.description", default: true)
    public var includeOnlineSearchResults: Bool
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.search \(\.$search)")
    }
    
    public func perform() async throws -> some ReturnsValue<[ItemEntity]> {
        try await .result(value: ItemEntityQuery.entities(matching: search, includeSuggestedEntities: includeOnlineSearchResults))
    }
}

