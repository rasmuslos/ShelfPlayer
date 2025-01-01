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
    static let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "Intents & SpotLight")
    
    static func run() async throws {
        #if ENABLE_ALL_FEATURES
        INPreferences.requestSiriAuthorization { _ in }
        #endif

        Task.detached {
            try? await UserContext.update()
            try? await UserContext.donateNextUpSuggestions()
        }

        SpotlightIndexer.index()
        IntentDonator.shared.ping()
    }
    
    private static func update() async throws {
        let context = INMediaUserContext()
        var totalCount = 0
        
        /*
        let libraries = try await AudiobookshelfClient.shared.libraries()
        for library in libraries {
            switch library.type {
            case .audiobooks:
                totalCount += try await AudiobookshelfClient.shared.audiobooks(libraryID: library.id, sortOrder: .added, ascending: false, limit: 0, page: nil).1
            case .podcasts:
                totalCount += try await AudiobookshelfClient.shared.podcasts(libraryID: library.id, limit: 0, page: nil).1
            default:
                break
            }
        }
         */
        
        context.subscriptionStatus = .subscribed
        context.numberOfLibraryItems = totalCount
        
        context.becomeCurrent()
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
