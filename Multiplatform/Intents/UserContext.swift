//
//  UserContext.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.09.24.
//

import Foundation
import Intents
import ShelfPlayerKit

internal struct UserContext {
    static func run() async throws {
        #if ENABLE_ALL_FEATURES
        INPreferences.requestSiriAuthorization { _ in }
        #endif

        Task.detached {
            try? await UserContext.update()
            try? await UserContext.donateNextUpSuggestions()
        }

        SpotlightIndexer.index()
    }
    
    private static func update() async throws {
        let context = INMediaUserContext()
        var totalCount = 0
        
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
        
        context.subscriptionStatus = .subscribed
        context.numberOfLibraryItems = totalCount
        
        context.becomeCurrent()
    }
    
    private static func donateNextUpSuggestions() async throws {
        var items: [Item] = []
        
        for libarary in try await AudiobookshelfClient.shared.libraries() {
            switch libarary.type {
            case .audiobooks:
                let home: ([HomeRow<Audiobook>], [HomeRow<Author>]) = try await AudiobookshelfClient.shared.home(libraryID: libarary.id)
                if let audiobooks = home.0.filter({ $0.id == "continue-listening" }).first?.entities {
                    items += audiobooks
                }
            case .podcasts:
                let home: ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await AudiobookshelfClient.shared.home(libraryID: libarary.id)
                if let episodes = home.1.filter({ $0.id == "continue-listening" }).first?.entities {
                    items += episodes
                }
            default:
                break
            }
        }
        
        INUpcomingMediaManager.shared.setPredictionMode(.default, for: .audioBook)
        INUpcomingMediaManager.shared.setPredictionMode(.default, for: .podcastShow)
        
        INUpcomingMediaManager.shared.setPredictionMode(.onlyPredictSuggestedIntents, for: .podcastEpisode)
        
        // MARK: TODO
        
        // INUpcomingMediaManager.shared.setSuggestedMediaIntents(<#T##intents: NSOrderedSet##NSOrderedSet#>)
    }
}
