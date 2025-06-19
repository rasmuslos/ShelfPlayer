//
//  PodcastEntity.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.06.25.
//

import Foundation
import AppIntents
import CoreTransferable

public struct PodcastEntity: AppEntity, IndexedEntity, PersistentlyIdentifiable {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.entity.item.podcast", numericFormat: "intent.entity.item \(placeholder: .int)")
    public static let defaultQuery = PodcastEntityQuery()
    
    public let hideInSpotlight: Bool = true
    
    public let podcast: Podcast
    public let imageData: Data?
    
    // Properties
    
    public var id: ItemIdentifier {
        podcast.id
    }
    
    @Property(title: "intent.entity.item.property.explicit")
    public var explicit: Bool
    
    @Property(title: "intent.entity.item.property.episodeCount")
    public var episodeCount: Int
    @Property(title: "intent.entity.item.property.incompleteEpisodeCount")
    public var incompleteEpisodeCount: Int?
    
    public init(podcast: Podcast) async {
        self.podcast = podcast
        imageData = await podcast.id.data(size: .small)
        
        explicit = podcast.explicit
        episodeCount = podcast.episodeCount
        incompleteEpisodeCount = podcast.incompleteEpisodeCount
    }
    
    public var displayRepresentation: DisplayRepresentation {
        let image: DisplayRepresentation.Image?
        
        if let imageData {
            image = .init(data: imageData, displayStyle: .default)
        } else {
            image = nil
        }
        
        return .init(title: "\(podcast.name)", subtitle: "\(podcast.authors.formatted(.list(type: .and)))", image: image)
    }
}
extension PodcastEntity: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation {
            $0.podcast
        }
    }
}

public struct PodcastEntityQuery: EntityQuery, EntityStringQuery {
    public init() {}
    
    public func entities(for identifiers: [ItemIdentifier]) async throws -> [PodcastEntity] {
        await withTaskGroup {
            for identifier in identifiers {
                $0.addTask { () -> PodcastEntity? in
                    guard let podcast = try? await identifier.resolved as? Podcast else {
                        return nil
                    }
                    
                    return await PodcastEntity(podcast: podcast)
                }
            }
            
            return await $0.compactMap { $0 }.reduce(into: []) { $0.append($1) }
        }
    }
    public func suggestedEntities() async throws -> [PodcastEntity] {
        await listenNowPodcastEntities()
    }
    
    public func entities(matching string: String) async throws -> [PodcastEntity] {
        try await Self.entities(matching: string, includeOnlineSearchResults: true)
    }
    public static func entities(matching string: String, includeOnlineSearchResults: Bool) async throws -> [PodcastEntity] {
        guard let podcasts = try await ShelfPlayerKit.globalSearch(query: string, includeOnlineSearchResults: includeOnlineSearchResults, allowedItemTypes: [.podcast]) as? [Podcast] else {
            throw IntentError.invalidItemType
        }
        
        return await withTaskGroup {
            for podcast in podcasts {
                $0.addTask {
                    await PodcastEntity(podcast: podcast)
                }
            }
            
            return await $0.reduce(into: []) { $0.append($1) }
        }
    }
}
struct PodcastEntityOptionsProvider: DynamicOptionsProvider {
    public func results() async throws -> [PodcastEntity] {
        await listenNowPodcastEntities()
    }
}

private func listenNowPodcastEntities() async -> [PodcastEntity] {
    var result = [PodcastEntity]()
    var podcastIDs = [ItemIdentifier]()
    
    for item in await ShelfPlayerKit.listenNowItems {
        guard let episode = item as? Episode else {
            continue
        }
        
        let podcastID = ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(episode.id)
        
        guard !podcastIDs.contains(podcastID) else {
            continue
        }
        
        guard let podcast = try? await podcastID.resolved as? Podcast else {
            continue
        }
        
        podcastIDs.append(podcastID)
        result.append(await .init(podcast: podcast))
    }
    
    return result
}


