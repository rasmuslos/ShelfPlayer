//
//  ItemEntity.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Foundation
import AppIntents
import CoreTransferable

@AssistantEntity(schema: .books.audiobook)
public struct ItemEntity: AppEntity, IndexedEntity, PersistentlyIdentifiable {
    /*
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.entity.item", numericFormat: "intent.entity.item \(placeholder: .int)", synonyms: [
        "intent.entity.item.audiobook",
        "intent.entity.item.podcast",
    ])
     */
    public static let defaultQuery = ItemEntityQuery()
    
    public let hideInSpotlight: Bool = true
    
    public let item: Item
    public let imageData: Data?
    
    // Properties
    
    public var id: ItemIdentifier {
        item.id
    }
    
    @Property
    public var title: String?
    @Property
    public var author: String?
    @Property
    public var genre: String?
    @Property
    public var purchaseDate: Date?
    @Property
    public var seriesTitle: String?
    @Property
    public var url: URL?
    
    public init(item: Item) async {
        self.item = item
        imageData = await item.id.data(size: .regular)
        
        title = item.name
        author = item.authors.formatted(.list(type: .and))
        genre = item.genres.formatted(.list(type: .and))
        purchaseDate = item.addedAt
        
        if let audiobook = item as? Audiobook, !audiobook.series.isEmpty {
            seriesTitle = audiobook.series.map(\.formattedName).formatted(.list(type: .and))
        } else {
            seriesTitle = nil
        }
        
        url = try? await item.id.url
    }
    
    public var displayRepresentation: DisplayRepresentation {
        let image: DisplayRepresentation.Image?
        
        if let imageData {
            image = .init(data: imageData, displayStyle: .default)
        } else {
            image = nil
        }
        
        let subtitle: String
        
        switch item.id.type {
            case .audiobook, .episode:
                subtitle = item.authors.formatted(.list(type: .and))
            default:
                subtitle = item.id.type.label
        }
        
        return .init(title: "\(item.name)", subtitle: "\(subtitle)", image: image)
    }
}
extension ItemEntity: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation {
            $0.item
        }
    }
}

public struct ItemEntityQuery: EntityQuery {
    public init() {}
    
    public func entities(for identifiers: [ItemIdentifier]) async throws -> [ItemEntity] {
        await withTaskGroup {
            for identifier in identifiers {
                $0.addTask {
                    try? await ItemEntity(item: identifier.resolved)
                }
            }
            
            return await $0.compactMap { $0 }.reduce(into: []) { $0.append($1) }
        }
    }
    public func suggestedEntities() async throws -> [ItemEntity] {
        await listenNowAppEntities()
    }
}

extension ItemEntityQuery: EntityStringQuery {
    public func entities(matching string: String) async throws -> [ItemEntity] {
        try await Self.entities(matching: string, includeSuggestedEntities: true)
    }
    public static func entities(matching string: String, includeSuggestedEntities: Bool) async throws -> [ItemEntity] {
        let items = try await ShelfPlayerKit.globalSearch(query: string, includeOnlineSearchResults: includeSuggestedEntities)
        
        return await withTaskGroup {
            for item in items {
                $0.addTask {
                    await ItemEntity(item: item)
                }
            }
            
            return await $0.reduce(into: []) { $0.append($1) }
        }
    }
}
struct ItemEntityOptionsProvider: DynamicOptionsProvider {
    public func results() async throws -> [ItemEntity] {
        await listenNowAppEntities()
    }
}

extension ItemIdentifier: EntityIdentifierConvertible {
    public var entityIdentifierString: String {
        description
    }
    
    public static func entityIdentifier(for entityIdentifierString: String) -> ItemIdentifier? {
        ItemIdentifier(entityIdentifierString)
    }
}

private func listenNowAppEntities() async -> [ItemEntity] {
    var result: [ItemEntity] = []
    
    for item in await ShelfPlayerKit.listenNowItems {
        result.append(await ItemEntity(item: item))
    }
    
    return result
}
