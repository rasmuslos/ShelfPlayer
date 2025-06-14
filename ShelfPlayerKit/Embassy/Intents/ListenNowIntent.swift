//
//  NowPlayingIntent 2.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 14.06.25.
//

import Foundation
import AppIntents

public struct ListenNowIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.listenNow"
    public static let description = IntentDescription("intent.listenNow.description")
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("intent.listenNow")
    }
    
    public func perform() async throws -> some ReturnsValue<[ItemEntity]> {
        return await .result(value: listenNowItemEntities())
    }
}
