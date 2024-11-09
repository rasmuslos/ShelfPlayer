//
//  SpotlightIndexer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.09.24.
//

import Foundation
import Intents
import CoreSpotlight
import Defaults
import ShelfPlayerKit

internal struct SpotlightIndexer {
    // 3 days
    static let indexWaitTime: TimeInterval = 60 * 60 * 24
    static let searchableIndex = CSSearchableIndex(name: "ShelfPlayer_Items", protectionClass: .completeUntilFirstUserAuthentication)
    
    static func index() {
        guard !NetworkMonitor.isRouteLimited else {
            return
        }
        
        let lastIndex = Defaults[.lastSpotlightIndex]
        var remainingIdentifiers = Defaults[.indexedIdentifiers]
        var indexedIdentifiers: [String] = []
        
        if let lastIndex, false {
            guard lastIndex.distance(to: .now) > indexWaitTime else {
                return
            }
        }
        
        Task {
            let libraries = try await AudiobookshelfClient.shared.libraries()
            var items: [CSSearchableItem] = []
            
            for library in libraries {
                switch library.type {
                case .audiobooks:
                    let (libraryItems, remaining, updated) = try await indexAudiobookLibrary(library, remainingIdentifiers: remainingIdentifiers)
                    
                    items += libraryItems
                    remainingIdentifiers = remaining
                    indexedIdentifiers += updated
                case .podcasts:
                    let (libraryItems, remaining, updated) = try await indexPodcastLibrary(library, remainingIdentifiers: remainingIdentifiers)
                    
                    items += libraryItems
                    remainingIdentifiers = remaining
                    indexedIdentifiers += updated
                default:
                    continue
                }
            }
            
            searchableIndex.beginBatch()
            
            UserContext.logger.info("Indexing \(items.count) items.")
            
            try await searchableIndex.indexSearchableItems(items)
            
            try await INInteraction.delete(with: remainingIdentifiers)
            try await searchableIndex.deleteSearchableItems(withIdentifiers: remainingIdentifiers)
            
            OfflineManager.shared.removeOutdated(identifiers: remainingIdentifiers)
            
            try await searchableIndex.endBatch(withClientState: .init())
            
            Defaults[.lastSpotlightIndex] = .now
            Defaults[.indexedIdentifiers] = indexedIdentifiers
            
            UserContext.logger.info("Indexed \(indexedIdentifiers.count) Spotlight items while deleting \(remainingIdentifiers.count) outdated items.")
        }
    }
    static func deleteIndex() {
        INInteraction.deleteAll()
        searchableIndex.deleteAllSearchableItems()
        
        Defaults[.lastSpotlightIndex] = nil
        Defaults[.indexedIdentifiers] = []
    }
    
    static func indexAudiobookLibrary(_ library: Library, remainingIdentifiers: [String]) async throws -> ([CSSearchableItem], [String], [String]) {
        var remainingIdentifiers = remainingIdentifiers
        var indexedIdentifiers: [String] = []
        var items: [CSSearchableItem] = []
        
        for audiobook in try await AudiobookshelfClient.shared.audiobooks(libraryID: library.id, sortOrder: .added, ascending: false, limit: nil, page: nil).0 {
            let identifier = convertIdentifier(item: audiobook)
            let identifierIndex = remainingIdentifiers.firstIndex(of: identifier)
            
            indexedIdentifiers.append(identifier)
            
            if let identifierIndex {
                remainingIdentifiers.remove(at: identifierIndex)
                continue
            }
            
            let attributeSet = CSSearchableItemAttributeSet(contentType: .audio)
            
            attributeSet.title = audiobook.name
            attributeSet.displayName = audiobook.name
            
            attributeSet.participants = audiobook.authors
            attributeSet.performers = audiobook.narrators
            
            attributeSet.comment = audiobook.description
            attributeSet.genre = audiobook.genres.first
            
            attributeSet.duration = NSNumber(floatLiteral: audiobook.duration)
            
            attributeSet.url = audiobook.url
            attributeSet.thumbnailData = await audiobook.cover?.data
            
            attributeSet.addedDate = audiobook.addedAt
            attributeSet.contentCreationDate = audiobook.addedAt
            attributeSet.userOwned = NSNumber(floatLiteral: audiobook.addedAt.timeIntervalSince1970)
            
            attributeSet.sharedItemContentType = .audio
            attributeSet.domainIdentifier = "io.rfk.shelfPlayer.audiobook"
            
            attributeSet.actionIdentifiers = ["play"]
            
            let item = CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: "io.rfk.shelfPlayer.audiobook", attributeSet: attributeSet)
            
            items.append(item)
        }
        
        for author in try await AudiobookshelfClient.shared.authors(libraryID: library.id) {
            let identifier = convertIdentifier(item: author)
            let identifierIndex = remainingIdentifiers.firstIndex(of: identifier)
            
            indexedIdentifiers.append(identifier)
            
            if let identifierIndex {
                remainingIdentifiers.remove(at: identifierIndex)
                continue
            }
            
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            
            attributeSet.title = author.name
            attributeSet.displayName = author.name
            
            attributeSet.thumbnailData = await author.cover?.data
            
            let item = CSSearchableItem(uniqueIdentifier: convertIdentifier(item: author), domainIdentifier: "io.rfk.shelfPlayer.author", attributeSet: attributeSet)
            
            items.append(item)
        }
        
        for series in try await AudiobookshelfClient.shared.series(libraryID: library.id, limit: nil, page: nil).0 {
            let identifier = convertIdentifier(item: series)
            let identifierIndex = remainingIdentifiers.firstIndex(of: identifier)
            
            indexedIdentifiers.append(identifier)
            
            if let identifierIndex {
                remainingIdentifiers.remove(at: identifierIndex)
                continue
            }
            
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            
            attributeSet.title = series.name
            attributeSet.displayName = series.name
            
            let item = CSSearchableItem(uniqueIdentifier: convertIdentifier(item: series), domainIdentifier: "io.rfk.shelfPlayer.series", attributeSet: attributeSet)
            
            items.append(item)
        }
        
        return (items, remainingIdentifiers, indexedIdentifiers)
    }
    static func indexPodcastLibrary(_ library: Library, remainingIdentifiers: [String]) async throws -> ([CSSearchableItem], [String], [String]) {
        var remainingIdentifiers = remainingIdentifiers
        var indexedIdentifiers: [String] = []
        var items: [CSSearchableItem] = []
        
        for podcast in try await AudiobookshelfClient.shared.podcasts(libraryID: library.id, limit: nil, page: nil).0 {
            let identifier = convertIdentifier(item: podcast)
            let identifierIndex = remainingIdentifiers.firstIndex(of: identifier)
            
            indexedIdentifiers.append(identifier)
            
            if let identifierIndex {
                remainingIdentifiers.remove(at: identifierIndex)
            } else {
                let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
                
                attributeSet.title = podcast.name
                attributeSet.displayName = podcast.name
                
                let item = CSSearchableItem(uniqueIdentifier: convertIdentifier(item: podcast), domainIdentifier: "io.rfk.shelfPlayer.podcast", attributeSet: attributeSet)
                
                items.append(item)
            }
            
            for episode in try await AudiobookshelfClient.shared.podcast(podcastId: podcast.id).1 {
                let identifier = convertIdentifier(item: episode)
                let identifierIndex = remainingIdentifiers.firstIndex(of: identifier)
                
                indexedIdentifiers.append(identifier)
                
                if let identifierIndex {
                    remainingIdentifiers.remove(at: identifierIndex)
                    continue
                }
                
                let attributeSet = CSSearchableItemAttributeSet(contentType: .audio)
                
                attributeSet.title = episode.name
                attributeSet.displayName = episode.name
                
                attributeSet.participants = episode.authors
                
                attributeSet.comment = episode.descriptionText
                attributeSet.genre = podcast.genres.first
                
                attributeSet.duration = NSNumber(floatLiteral: episode.duration)
                
                attributeSet.url = episode.url
                attributeSet.thumbnailData = await episode.cover?.data
                
                attributeSet.addedDate = episode.addedAt
                attributeSet.contentCreationDate = episode.addedAt
                attributeSet.userOwned = NSNumber(floatLiteral: episode.addedAt.timeIntervalSince1970)
                
                attributeSet.sharedItemContentType = .audio
                attributeSet.domainIdentifier = "io.rfk.shelfPlayer.episode"
                
                attributeSet.containerIdentifier = convertIdentifier(item: podcast)
                attributeSet.containerTitle = podcast.name
                attributeSet.containerDisplayName = podcast.name
                attributeSet.containerOrder = NSNumber(integerLiteral: episode.index)
                
                attributeSet.actionIdentifiers = ["play", "viewPodcast"]
                
                let item = CSSearchableItem(uniqueIdentifier: convertIdentifier(item: episode), domainIdentifier: "io.rfk.shelfPlayer.episode", attributeSet: attributeSet)
                
                items.append(item)
            }
        }
        
        return (items, remainingIdentifiers, indexedIdentifiers)
    }
}
