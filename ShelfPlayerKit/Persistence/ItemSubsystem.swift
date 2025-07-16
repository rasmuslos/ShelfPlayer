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
    public final class ItemSubsystem: Sendable {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ItemSubsystem")
    }
}

public extension PersistenceManager.ItemSubsystem {
    func playbackRate(for itemID: ItemIdentifier) async -> Percentage? {
        await PersistenceManager.shared.keyValue[.playbackRate(for: itemID)]
    }
    func setPlaybackRate(_ rate: Percentage?, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.playbackRate(for: itemID), rate)
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
        if let stored = await PersistenceManager.shared.keyValue[.dominantColor(of: itemID)] {
            let components = stored.split(separator: ":").map { Double($0) ?? 0 }
            return Color(red: components[0], green: components[1], blue: components[2])
        }
        
        let size: ImageSize
        
        switch itemID.type {
            case .audiobook:
                size = .regular
            case .podcast:
                size = .large
            case .episode:
                size = .tiny
            default:
                size = .tiny
        }
        
        guard let image = await ImageLoader.shared.platformImage(for: .init(itemID: itemID, size: size)), let extracted = try? await RFKVisuals.extractDominantColors(5, image: image) else {
            return nil
        }
        
        let colors = extracted.sorted { $0.percentage > $1.percentage }.map(\.color)
        
        let result: Color?
        
        switch itemID.type {
            case .podcast:
                result = RFKVisuals.brightnessExtremeFilter(colors, threshold: 0.1).first
            default:
                if let highBrightness = RFKVisuals.brightnessExtremeFilter(colors, threshold: 0.4).randomElement() {
                    result = highBrightness
                } else if let mediumBrightness = RFKVisuals.brightnessExtremeFilter(colors, threshold: 0.3).randomElement() {
                    result = mediumBrightness
                } else {
                    let filtered = RFKVisuals.brightnessExtremeFilter(colors, threshold: 0.2)
                    
                    if let highlySaturated = RFKVisuals.saturationExtremeFilter(filtered, threshold: 0.4).randomElement() {
                        result = highlySaturated
                    } else {
                        result = filtered.randomElement()
                    }
                }
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
    
    func libraryIndexMetadata(for library: Library) async -> LibraryIndexMetadata? {
        await PersistenceManager.shared.keyValue[.libraryIndexMetadata(of: library.id, connectionID: library.connectionID)]
    }
    func setLibraryIndexMetadata(_ metadata: LibraryIndexMetadata?, for library: Library) async throws {
        try await PersistenceManager.shared.keyValue.set(.libraryIndexMetadata(of: library.id, connectionID: library.connectionID), metadata)
    }
    
    func libraryIndexedIDs(for library: Library, subset: String) async -> [ItemIdentifier] {
        await PersistenceManager.shared.keyValue[.libraryIndexedIDs(of: library.id, connectionID: library.connectionID, subset: subset)] ?? []
    }
    func setLibraryIndexedIDs(_ IDs: [ItemIdentifier], for library: Library, subset: String) async throws {
        try await PersistenceManager.shared.keyValue.set(.libraryIndexedIDs(of: library.id, connectionID: library.connectionID, subset: subset), IDs)
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
    
    static func upNextStrategy(for itemID: ItemIdentifier) -> Key<ConfigureableUpNextStrategy> {
        Key(identifier: "upNextStrategy-\(itemID)", cluster: "upNextStrategy", isCachePurgeable: false)
    }
    static func allowSuggestions(for itemID: ItemIdentifier) -> Key<Bool> {
        Key(identifier: "allowSuggestions-\(itemID)", cluster: "allowSuggestions", isCachePurgeable: false)
    }
    
    static func dominantColor(of itemID: ItemIdentifier) -> Key<String> {
        Key(identifier: "dominantColor-\(itemID)", cluster: "dominantColors", isCachePurgeable: true)
    }
    
    static func libraryIndexMetadata(of libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID) -> Key<PersistenceManager.ItemSubsystem.LibraryIndexMetadata> {
        Key(identifier: "libraryIndexMetadata-\(libraryID)-\(connectionID)", cluster: "libraryIndexMetadata", isCachePurgeable: true)
    }
    static func libraryIndexedIDs(of libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID, subset: String) -> Key<[ItemIdentifier]> {
        Key(identifier: "libraryIndexMetadata-\(libraryID)-\(connectionID)-\(subset)", cluster: "libraryIndexedIDs", isCachePurgeable: false)
    }
    
    static func podcastFilterSortConfiguration(for podcastID: ItemIdentifier) -> Key<PersistenceManager.ItemSubsystem.PodcastFilterSortConfiguration> {
        Key(identifier: "podcastFilterSortConfigurations-\(podcastID)", cluster: "podcastFilterSortConfigurations", isCachePurgeable: false)
    }
}
