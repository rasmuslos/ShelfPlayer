//
//  AudiobookEntity.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.06.25.
//

import Foundation
import AppIntents
import CoreTransferable

@AssistantEntity(schema: .books.audiobook)
public struct AudiobookEntity: AppEntity, IndexedEntity, PersistentlyIdentifiable {
    public static let defaultQuery = AudiobookEntityQuery()
    
    public let hideInSpotlight: Bool = true
    
    public let audiobook: Audiobook
    public let imageData: Data?
    
    // Properties
    
    public var id: ItemIdentifier {
        audiobook.id
    }
    
    public var title: String?
    public var author: String?
    public var genre: String?
    public var purchaseDate: Date?
    public var seriesTitle: String?
    public var url: URL?
    
    @Property(title: "intent.entity.item.property.subtitle")
    public var subtitle: String?
    
    @Property(title: "intent.entity.item.property.narrators")
    public var narrators: [String]?
    
    @Property(title: "intent.entity.item.property.explicit")
    public var explicit: Bool?
    @Property(title: "intent.entity.item.property.abridged")
    public var abridged: Bool?
    
    public init(audiobook: Audiobook) async {
        self.audiobook = audiobook
        imageData = await audiobook.id.data(size: .small)
        
        title = audiobook.name
        author = audiobook.authors.formatted(.list(type: .and))
        genre = audiobook.genres.formatted(.list(type: .and))
        purchaseDate = audiobook.addedAt
        
        seriesTitle = audiobook.series.map(\.formattedName).formatted(.list(type: .and))
        
        url = try? await audiobook.id.url
        
        subtitle = audiobook.subtitle
        narrators = audiobook.narrators
        explicit = audiobook.explicit
        abridged = audiobook.abridged
    }
    
    public var displayRepresentation: DisplayRepresentation {
        let image: DisplayRepresentation.Image?
        
        if let imageData {
            image = .init(data: imageData, displayStyle: .default)
        } else {
            image = nil
        }
        
        return .init(title: "\(audiobook.name)", subtitle: "\(audiobook.authors.formatted(.list(type: .and)))", image: image)
    }
}
extension AudiobookEntity: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation {
            $0.audiobook
        }
    }
}

public struct AudiobookEntityQuery: EntityQuery, EntityStringQuery {
    public init() {}
    
    public func entities(for identifiers: [ItemIdentifier]) async throws -> [AudiobookEntity] {
        await withTaskGroup {
            for identifier in identifiers {
                $0.addTask { () -> AudiobookEntity? in
                    guard let audiobook = try? await identifier.resolved as? Audiobook else {
                        return nil
                    }
                    
                    return await AudiobookEntity(audiobook: audiobook)
                }
            }
            
            return await $0.compactMap { $0 }.reduce(into: []) { $0.append($1) }
        }
    }
    public func suggestedEntities() async throws -> [AudiobookEntity] {
        await listenNowAudiobookEntities()
    }
    
    public func entities(matching string: String) async throws -> [AudiobookEntity] {
        try await Self.entities(matching: string, includeOnlineSearchResults: true)
    }
    public static func entities(matching string: String, includeOnlineSearchResults: Bool) async throws -> [AudiobookEntity] {
        guard let audiobooks = try await ShelfPlayerKit.globalSearch(query: string, includeOnlineSearchResults: includeOnlineSearchResults, allowedItemTypes: [.audiobook]) as? [Audiobook] else {
            throw IntentError.invalidItemType
        }
        
        return await withTaskGroup {
            for audiobook in audiobooks {
                $0.addTask {
                    await AudiobookEntity(audiobook: audiobook)
                }
            }
            
            return await $0.reduce(into: []) { $0.append($1) }
        }
    }
}
struct AudiobookEntityOptionsProvider: DynamicOptionsProvider {
    public func results() async throws -> [AudiobookEntity] {
        await listenNowAudiobookEntities()
    }
}

private func listenNowAudiobookEntities() async -> [AudiobookEntity] {
    var result = [AudiobookEntity]()
    
    for item in await ShelfPlayerKit.listenNowItems {
        guard let audiobook = item as? Audiobook else {
            continue
        }
        
        result.append(await AudiobookEntity(audiobook: audiobook))
    }
    
    return result
}

