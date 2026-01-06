//
//  ItemSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.02.25.
//

import Foundation
import SwiftUI
import SwiftData
import OSLog

import RFVisuals

extension PersistenceManager {
    public final actor ItemSubsystem: Sendable {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ItemSubsystem")
        
        var colorCache = [ItemIdentifier: Task<Color?, Never>]()
    }
}

public extension PersistenceManager.ItemSubsystem {
    func playbackRate(for itemID: ItemIdentifier) async -> Percentage? {
        await PersistenceManager.shared.keyValue[.playbackRate(for: itemID)]
    }
    func setPlaybackRate(_ rate: Percentage?, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.playbackRate(for: itemID), rate)
    }
    func sleepTimer(for itemID: ItemIdentifier) async -> SleepTimerConfiguration? {
        await PersistenceManager.shared.keyValue[.sleepTimer(for: itemID)]
    }
    func setSleepTimer(_ sleepTimer: SleepTimerConfiguration?, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.sleepTimer(for: itemID), sleepTimer)
    }
    
    func upNextStrategy(for itemID: ItemIdentifier) async -> ConfigureableUpNextStrategy? {
        await PersistenceManager.shared.keyValue[.upNextStrategy(for: itemID)]
    }
    func setUpNextStrategy(_ strategy: ConfigureableUpNextStrategy?, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.upNextStrategy(for: itemID), strategy)
    }
    func allowSuggestions(for itemID: ItemIdentifier) async -> Bool? {
        await PersistenceManager.shared.keyValue[.allowSuggestions(for: itemID)]
    }
    func setAllowSuggestions(_ allowed: Bool?, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.allowSuggestions(for: itemID), allowed)
    }
    
    func dominantColor(of itemID: ItemIdentifier) async -> Color? {
        #if DEBUG
        if itemID.connectionID == "fixture" {
            return .orange
        }
        #endif
        
        if colorCache[itemID] == nil {
            colorCache[itemID] = .init {
                if let stored = await PersistenceManager.shared.keyValue[.dominantColor(of: itemID)] {
                    let components = stored.split(separator: ":").map { Double($0) ?? 0 }
                    return Color(red: components[0], green: components[1], blue: components[2])
                }
                
                let size: ImageSize
                
                switch itemID.type {
                    case .audiobook, .episode, .podcast:
                        size = .regular
                    default:
                        size = .tiny
                }
                
                guard let image = await ImageLoader.shared.platformImage(for: .init(itemID: itemID, size: size)) else {
                    return nil
                }
                
                let result: Color?
                
                switch itemID.type {
                    case .podcast:
                        guard let colors = try? await RFKVisuals.extractDominantColors(4, image: image) else {
                            return nil
                        }
                        
                        let prepared = RFKVisuals.prepareForFiltering(colors)
                        
                        result = prepared.filter { $0.brightness > 0.3 && $0.saturation > 0.2 }.sorted { $0.percentage > $1.percentage }.first?.color
                    default:
                        guard let colors = try? await RFKVisuals.extractDominantColors(6, image: image) else {
                            return nil
                        }
                        
                        let prepared = RFKVisuals.prepareForFiltering(colors)
                        
                        result = prepared.filter { $0.brightness > 0.3 && $0.saturation > 0.4 }.randomElement()?.color
                            ?? prepared.filter { $0.brightness > 0.3 && $0.saturation > 0.2 }.randomElement()?.color
                }
                
                guard let result else {
                    return nil
                }
                
                let resolved = result.resolve(in: .init())
                let stored = "\(resolved.red):\(resolved.green):\(resolved.blue)"
                
                do {
                    try await PersistenceManager.shared.keyValue.set(.dominantColor(of: itemID), stored)
                } catch {
                    logger.error("Failed to store color for \(itemID): \(error)")
                }
                
                return result
            }
        }
        
        return await colorCache[itemID]?.value
    }
    
    func libraryIndexMetadata(for libraryID: LibraryIdentifier) async -> LibraryIndexMetadata? {
        await PersistenceManager.shared.keyValue[.libraryIndexMetadata(of: libraryID)]
    }
    func setLibraryIndexMetadata(_ metadata: LibraryIndexMetadata?, for libraryID: LibraryIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.libraryIndexMetadata(of: libraryID), metadata)
    }
    
    func libraryIndexedIDs(for libraryID: LibraryIdentifier, subset: String) async -> [ItemIdentifier] {
        await PersistenceManager.shared.keyValue[.libraryIndexedIDs(of: libraryID, subset: subset)] ?? []
    }
    func setLibraryIndexedIDs(_ IDs: [ItemIdentifier], for libraryID: LibraryIdentifier, subset: String) async throws {
        try await PersistenceManager.shared.keyValue.set(.libraryIndexedIDs(of: libraryID, subset: subset), IDs)
    }
    
    func podcastFilterSortConfiguration(for podcastID: ItemIdentifier) async -> PodcastFilterSortConfiguration {
        await PersistenceManager.shared.keyValue[.podcastFilterSortConfiguration(for: podcastID)] ?? .init(sortOrder: Defaults[.defaultEpisodeSortOrder],
                                                                                                           ascending: Defaults[.defaultEpisodeAscending],
                                                                                                           filter: .notFinished,
                                                                                                           restrictToPersisted: false,
                                                                                                           seasonFilter: nil)
    }
    func setPodcastFilterSortConfiguration(_ configuration: PodcastFilterSortConfiguration, for podcastID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.podcastFilterSortConfiguration(for: podcastID), configuration)
    }
    
    struct LibraryIndexMetadata: Codable, Sendable {
        public var page = 0
        public var totalItemCount: Int!
        
        public var startDate: Date?
        public var endDate: Date?
        
        public init() {
            totalItemCount = nil
        }
        
        public var isFinished: Bool {
            endDate != nil
        }
    }
    struct PodcastFilterSortConfiguration: Codable, Sendable {
        public let sortOrder: EpisodeSortOrder
        public let ascending: Bool
        
        public let filter: ItemFilter
        public let restrictToPersisted: Bool
        
        public let seasonFilter: String?
        
        public init(sortOrder: EpisodeSortOrder, ascending: Bool, filter: ItemFilter, restrictToPersisted: Bool, seasonFilter: String?) {
            self.sortOrder = sortOrder
            self.ascending = ascending
            self.filter = filter
            self.restrictToPersisted = restrictToPersisted
            self.seasonFilter = seasonFilter
        }
    }
}

extension PersistenceManager.ItemSubsystem {
    func invalidate() {
        colorCache.removeAll()
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    // Contains the stored rate for playable items (audiobook, episode) and overrides for others (author, series,  podcast)
    static func playbackRate(for itemID: ItemIdentifier) -> Key<Percentage> {
        let isPurgeable: Bool
        
        switch itemID.type {
            case .audiobook, .episode:
                isPurgeable = true
            case .author, .narrator, .series, .podcast, .collection, .playlist:
                isPurgeable = false
        }
        
        return Key(identifier: "playbackRate-\(itemID)", cluster: "playbackRates", isCachePurgeable: isPurgeable)
    }
    static func sleepTimer(for itemID: ItemIdentifier) -> Key<SleepTimerConfiguration> {
        Key(identifier: "sleepTimer-\(itemID)", cluster: "sleepTimers", isCachePurgeable: false)
    }
    
    static func upNextStrategy(for itemID: ItemIdentifier) -> Key<ConfigureableUpNextStrategy> {
        Key(identifier: "upNextStrategy-\(itemID)", cluster: "upNextStrategy", isCachePurgeable: false)
    }
    static func allowSuggestions(for itemID: ItemIdentifier) -> Key<Bool> {
        Key(identifier: "allowSuggestions-\(itemID)", cluster: "allowSuggestions", isCachePurgeable: false)
    }
    
    static func dominantColor(of itemID: ItemIdentifier) -> Key<String> {
        Key(identifier: "dominantColor-\(itemID)", cluster: "dominantColors", isCachePurgeable: true)
    }
    
    static func libraryIndexMetadata(of libraryID: LibraryIdentifier) -> Key<PersistenceManager.ItemSubsystem.LibraryIndexMetadata> {
        Key(identifier: "libraryIndexMetadata-\(libraryID.libraryID)-\(libraryID.connectionID)", cluster: "libraryIndexMetadata", isCachePurgeable: true)
    }
    static func libraryIndexedIDs(of libraryID: LibraryIdentifier, subset: String) -> Key<[ItemIdentifier]> {
        Key(identifier: "libraryIndexMetadata-\(libraryID.libraryID)-\(libraryID.connectionID)-\(subset)", cluster: "libraryIndexedIDs", isCachePurgeable: false)
    }
    
    static func podcastFilterSortConfiguration(for podcastID: ItemIdentifier) -> Key<PersistenceManager.ItemSubsystem.PodcastFilterSortConfiguration> {
        Key(identifier: "podcastFilterSortConfigurations-\(podcastID)", cluster: "podcastFilterSortConfigurations", isCachePurgeable: false)
    }
}
