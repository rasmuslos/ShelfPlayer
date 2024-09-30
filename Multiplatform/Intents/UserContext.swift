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
    static func update() async throws {
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
        
        print(totalCount)
        
        context.subscriptionStatus = .subscribed
        context.numberOfLibraryItems = totalCount
        
        context.becomeCurrent()
    }
}
