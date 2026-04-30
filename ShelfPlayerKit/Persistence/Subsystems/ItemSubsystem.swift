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

typealias PersistedPlaybackRate = ShelfPlayerSchema.PersistedPlaybackRate
typealias PersistedSleepTimerConfig = ShelfPlayerSchema.PersistedSleepTimerConfig
typealias PersistedUpNextStrategy_ = ShelfPlayerSchema.PersistedUpNextStrategy
typealias PersistedDominantColor = ShelfPlayerSchema.PersistedDominantColor
typealias PersistedPodcastFilterSort = ShelfPlayerSchema.PersistedPodcastFilterSort
typealias PersistedLibraryIndex = ShelfPlayerSchema.PersistedLibraryIndex

extension PersistenceManager {
    @ModelActor
    public final actor ItemSubsystem: Sendable {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ItemSubsystem")

        var colorCache = [ItemIdentifier: Task<Color?, Never>]()
    }
}

public extension PersistenceManager.ItemSubsystem {
    func playbackRate(for itemID: ItemIdentifier) -> Percentage? {
        let key = itemID.description
        let entity: PersistedPlaybackRate?
        do {
            entity = try modelContext.fetch(FetchDescriptor<PersistedPlaybackRate>(predicate: #Predicate { $0.itemID == key })).first
        } catch {
            logger.warning("Failed to fetch playback rate for \(itemID, privacy: .public): \(error, privacy: .public)")
            return nil
        }
        return entity?.rate
    }
    func setPlaybackRate(_ rate: Percentage?, for itemID: ItemIdentifier) throws {
        let key = itemID.description

        if let rate {
            let isCachePurgeable: Bool
            switch itemID.type {
            case .audiobook, .episode:
                isCachePurgeable = true
            case .author, .narrator, .series, .podcast, .collection, .playlist:
                isCachePurgeable = false
            }

            if let existing = try modelContext.fetch(FetchDescriptor<PersistedPlaybackRate>(predicate: #Predicate { $0.itemID == key })).first {
                existing.rate = rate
            } else {
                modelContext.insert(PersistedPlaybackRate(itemID: key, rate: rate, isCachePurgeable: isCachePurgeable))
            }
        } else {
            try modelContext.delete(model: PersistedPlaybackRate.self, where: #Predicate { $0.itemID == key })
        }

        try modelContext.save()
    }

    func sleepTimer(for itemID: ItemIdentifier) -> SleepTimerConfiguration? {
        let key = itemID.description
        let entity: PersistedSleepTimerConfig?
        do {
            entity = try modelContext.fetch(FetchDescriptor<PersistedSleepTimerConfig>(predicate: #Predicate { $0.itemID == key })).first
        } catch {
            logger.warning("Failed to fetch sleep timer for \(itemID, privacy: .public): \(error, privacy: .public)")
            return nil
        }
        guard let entity else { return nil }
        do {
            return try JSONDecoder().decode(SleepTimerConfiguration.self, from: entity.configData)
        } catch {
            logger.warning("Failed to decode sleep timer for \(itemID, privacy: .public): \(error, privacy: .public)")
            return nil
        }
    }
    func setSleepTimer(_ sleepTimer: SleepTimerConfiguration?, for itemID: ItemIdentifier) throws {
        let key = itemID.description

        if let sleepTimer {
            let data = try JSONEncoder().encode(sleepTimer)

            if let existing = try modelContext.fetch(FetchDescriptor<PersistedSleepTimerConfig>(predicate: #Predicate { $0.itemID == key })).first {
                existing.configData = data
            } else {
                modelContext.insert(PersistedSleepTimerConfig(itemID: key, configData: data))
            }
        } else {
            try modelContext.delete(model: PersistedSleepTimerConfig.self, where: #Predicate { $0.itemID == key })
        }

        try modelContext.save()
    }

    func upNextStrategy(for itemID: ItemIdentifier) -> ConfigureableUpNextStrategy? {
        let key = itemID.description
        guard let entity = try? modelContext.fetch(FetchDescriptor<PersistedUpNextStrategy_>(predicate: #Predicate { $0.itemID == key })).first else { return nil }
        return ConfigureableUpNextStrategy(rawValue: entity.strategy)
    }
    func setUpNextStrategy(_ strategy: ConfigureableUpNextStrategy?, for itemID: ItemIdentifier) throws {
        let key = itemID.description

        if let strategy {
            if let existing = try modelContext.fetch(FetchDescriptor<PersistedUpNextStrategy_>(predicate: #Predicate { $0.itemID == key })).first {
                existing.strategy = strategy.rawValue
            } else {
                modelContext.insert(PersistedUpNextStrategy_(itemID: key, strategy: strategy.rawValue))
            }
        } else {
            try modelContext.delete(model: PersistedUpNextStrategy_.self, where: #Predicate { $0.itemID == key })
        }

        try modelContext.save()
    }

    func allowSuggestions(for itemID: ItemIdentifier) -> Bool? {
        let key = itemID.description
        do {
            return try modelContext.fetch(FetchDescriptor<PersistedUpNextStrategy_>(predicate: #Predicate { $0.itemID == key })).first?.allowSuggestions
        } catch {
            logger.warning("Failed to fetch up-next strategy for \(itemID, privacy: .public): \(error, privacy: .public)")
            return nil
        }
    }
    func setAllowSuggestions(_ allowed: Bool?, for itemID: ItemIdentifier) throws {
        let key = itemID.description

        if let existing = try modelContext.fetch(FetchDescriptor<PersistedUpNextStrategy_>(predicate: #Predicate { $0.itemID == key })).first {
            existing.allowSuggestions = allowed
        } else if let allowed {
            modelContext.insert(PersistedUpNextStrategy_(itemID: key, strategy: "", allowSuggestions: allowed))
        }

        try modelContext.save()
    }

    func dominantColor(of itemID: ItemIdentifier) async -> Color? {
        #if DEBUG
        if itemID.libraryID == "fixture" {
            return .orange
        }
        #endif

        if colorCache[itemID] == nil {
            colorCache[itemID] = .init {
                let key = itemID.description

                if let stored = try? self.modelContext.fetch(FetchDescriptor<PersistedDominantColor>(predicate: #Predicate { $0.itemID == key })).first {
                    return Color(red: stored.red, green: stored.green, blue: stored.blue)
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

                let entity = PersistedDominantColor(itemID: key, red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue))
                self.modelContext.insert(entity)

                do {
                    try self.modelContext.save()
                } catch {
                    self.logger.error("Failed to store color for \(itemID): \(error)")
                }

                return result
            }
        }

        return await colorCache[itemID]?.value
    }

    func libraryIndexMetadata(for libraryID: LibraryIdentifier) -> LibraryIndexMetadata? {
        let key = "\(libraryID.libraryID)-\(libraryID.connectionID)"

        guard let entity = try? modelContext.fetch(FetchDescriptor<PersistedLibraryIndex>(predicate: #Predicate { $0.libraryKey == key })).first else { return nil }

        return LibraryIndexMetadata(page: entity.page, totalItemCount: entity.totalItemCount, startDate: entity.startDate, endDate: entity.endDate)
    }
    func setLibraryIndexMetadata(_ metadata: LibraryIndexMetadata?, for libraryID: LibraryIdentifier) throws {
        let key = "\(libraryID.libraryID)-\(libraryID.connectionID)"

        if let metadata {
            if let existing = try modelContext.fetch(FetchDescriptor<PersistedLibraryIndex>(predicate: #Predicate { $0.libraryKey == key })).first {
                existing.page = metadata.page
                existing.totalItemCount = metadata.totalItemCount
                existing.startDate = metadata.startDate
                existing.endDate = metadata.endDate
            } else {
                modelContext.insert(PersistedLibraryIndex(libraryKey: key, page: metadata.page, totalItemCount: metadata.totalItemCount, startDate: metadata.startDate, endDate: metadata.endDate))
            }
        } else {
            try modelContext.delete(model: PersistedLibraryIndex.self, where: #Predicate { $0.libraryKey == key })
        }

        try modelContext.save()
    }

    func libraryIndexedIDs(for libraryID: LibraryIdentifier, subset: String) -> [ItemIdentifier] {
        let key = "\(libraryID.libraryID)-\(libraryID.connectionID)-\(subset)"

        guard let entity = try? modelContext.fetch(FetchDescriptor<PersistedLibraryIndex>(predicate: #Predicate { $0.libraryKey == key })).first,
              let data = entity.indexedIDsData else { return [] }

        return (try? JSONDecoder().decode([ItemIdentifier].self, from: data)) ?? []
    }
    func setLibraryIndexedIDs(_ IDs: [ItemIdentifier], for libraryID: LibraryIdentifier, subset: String) throws {
        let key = "\(libraryID.libraryID)-\(libraryID.connectionID)-\(subset)"
        let data = try JSONEncoder().encode(IDs)

        if let existing = try modelContext.fetch(FetchDescriptor<PersistedLibraryIndex>(predicate: #Predicate { $0.libraryKey == key })).first {
            existing.indexedIDsData = data
        } else {
            let entity = PersistedLibraryIndex(libraryKey: key, page: 0, indexedIDsData: data)
            modelContext.insert(entity)
        }

        try modelContext.save()
    }

    func podcastFilterSortConfiguration(for podcastID: ItemIdentifier) -> PodcastFilterSortConfiguration {
        let key = podcastID.description

        guard let entity = try? modelContext.fetch(FetchDescriptor<PersistedPodcastFilterSort>(predicate: #Predicate { $0.podcastID == key })).first else {
            return .init(sortOrder: AppSettings.shared.defaultEpisodeSortOrder,
                         ascending: AppSettings.shared.defaultEpisodeAscending,
                         filter: .notFinished,
                         restrictToPersisted: false,
                         seasonFilter: nil)
        }

        return .init(sortOrder: EpisodeSortOrder(rawValue: entity.sortOrder) ?? .index,
                     ascending: entity.ascending,
                     filter: ItemFilter(rawValue: entity.filter) ?? .notFinished,
                     restrictToPersisted: entity.restrictToPersisted,
                     seasonFilter: entity.seasonFilter)
    }
    func setPodcastFilterSortConfiguration(_ configuration: PodcastFilterSortConfiguration, for podcastID: ItemIdentifier) throws {
        let key = podcastID.description

        if let existing = try modelContext.fetch(FetchDescriptor<PersistedPodcastFilterSort>(predicate: #Predicate { $0.podcastID == key })).first {
            existing.sortOrder = configuration.sortOrder.rawValue
            existing.ascending = configuration.ascending
            existing.filter = configuration.filter.rawValue
            existing.restrictToPersisted = configuration.restrictToPersisted
            existing.seasonFilter = configuration.seasonFilter
        } else {
            modelContext.insert(PersistedPodcastFilterSort(podcastID: key,
                                                           sortOrder: configuration.sortOrder.rawValue,
                                                           ascending: configuration.ascending,
                                                           filter: configuration.filter.rawValue,
                                                           restrictToPersisted: configuration.restrictToPersisted,
                                                           seasonFilter: configuration.seasonFilter))
        }

        try modelContext.save()
    }

    struct LibraryIndexMetadata: Codable, Sendable {
        public var page = 0
        public var totalItemCount: Int!

        public var startDate: Date?
        public var endDate: Date?

        public init() {
            totalItemCount = nil
        }

        init(page: Int, totalItemCount: Int?, startDate: Date?, endDate: Date?) {
            self.page = page
            self.totalItemCount = totalItemCount
            self.startDate = startDate
            self.endDate = endDate
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

    public func resetLibraryIndices() throws {
        try modelContext.delete(model: PersistedLibraryIndex.self)
        try modelContext.save()
    }

    func removePersistedData(itemID: ItemIdentifier) {
        let key = itemID.description

        try? modelContext.delete(model: PersistedPlaybackRate.self, where: #Predicate { $0.itemID == key })
        try? modelContext.delete(model: PersistedSleepTimerConfig.self, where: #Predicate { $0.itemID == key })
        try? modelContext.delete(model: PersistedUpNextStrategy_.self, where: #Predicate { $0.itemID == key })
        try? modelContext.delete(model: PersistedDominantColor.self, where: #Predicate { $0.itemID == key })
        try? modelContext.delete(model: PersistedPodcastFilterSort.self, where: #Predicate { $0.podcastID == key })

        try? modelContext.save()
    }

    func purgeCachedData(itemID: ItemIdentifier) {
        let key = itemID.description

        try? modelContext.delete(model: PersistedPlaybackRate.self, where: #Predicate { $0.itemID == key && $0.isCachePurgeable })
        try? modelContext.delete(model: PersistedDominantColor.self, where: #Predicate { $0.itemID == key })

        try? modelContext.save()
    }

    func purgeCachedData() {
        try? modelContext.delete(model: PersistedPlaybackRate.self, where: #Predicate { $0.isCachePurgeable })
        try? modelContext.delete(model: PersistedDominantColor.self)

        try? modelContext.save()
    }
}
