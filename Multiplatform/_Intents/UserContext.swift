//
//  UserContext.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.09.24.
//

import Foundation
import OSLog
import Intents
import ShelfPlayerKit

internal struct UserContext {
    static let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "Intents & Spotlight")
    
    static func run() async throws {
        Task.detached {
            try? await UserContext.donateNextUpSuggestions()
        }

        // SpotlightIndexer.index()
        IntentDonator.shared.ping()
    }
    
    private static func donateNextUpSuggestions() async throws {
        let items = try await IntentHelper.nextUp()
        
        INUpcomingMediaManager.shared.setPredictionMode(.default, for: .audioBook)
        INUpcomingMediaManager.shared.setPredictionMode(.default, for: .podcastShow)
        
        INUpcomingMediaManager.shared.setPredictionMode(.onlyPredictSuggestedIntents, for: .podcastEpisode)
        
        var intents = [INPlayMediaIntent]()
        
        for item in items {
            guard let intent = await IntentHelper.createIntent(item: item) else { continue }
            intents.append(intent)
        }
        
        INUpcomingMediaManager.shared.setSuggestedMediaIntents(NSOrderedSet(array: intents))
        
        logger.info("Donated \(intents.count) suggestions")
    }
}
