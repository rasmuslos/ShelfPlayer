//
//  ItemEntity.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Foundation
import AppIntents
import CoreTransferable

public struct ItemEntity: AppEntity, IndexedEntity, PersistentlyIdentifiable, Identifiable {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.entity.item", numericFormat: "intent.entity.item \(placeholder: .int)", synonyms: [
        "intent.entity.item.audiobook",
        "intent.entity.item.series",
        "intent.entity.item.author",
        "intent.entity.item.episode",
        "intent.entity.item.podcast",
    ])
    public static let defaultQuery = ItemEntityQuery()
    
    public let hideInSpotlight: Bool = true
    
    public let item: Item
    public let imageData: Data?
    
    // Properties
    
    public var id: ItemIdentifier {
        item.id
    }
    
    @Property(title: "intent.entity.item.property.identifier")
    public var identifier: String
    @Property(title: "intent.entity.item.property.title")
    public var title: String
    @Property(title: "intent.entity.item.property.authors")
    public var authors: [String]
    @Property(title: "intent.entity.item.property.description")
    public var description: String?
    @Property(title: "intent.entity.item.property.genres")
    public var genres: [String]
    @Property(title: "intent.entity.item.property.addedAt")
    public var addedAt: Date
    @Property(title: "intent.entity.item.property.released")
    public var released: String?
    
    @Property(title: "intent.entity.item.property.url")
    public var url: URL?
    
    public init(item: Item) async {
        self.item = item
        imageData = await item.id.data(size: .small)
        
        identifier = item.id.description
        title = item.name
        authors = item.authors
        description = item.description
        genres = item.genres
        addedAt = item.addedAt
        released = item.released
        
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

public struct ItemEntityQuery: EntityQuery, EntityStringQuery {
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
        await listenNowItemEntities()
    }
    
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
        await listenNowItemEntities()
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

func listenNowItemEntities() async -> [ItemEntity] {
    var result = [ItemEntity]()
    
    guard let items = try? await PersistenceManager.shared.listenNow.current else {
        return []
    }
    
    for item in items {
        result.append(await .init(item: item))
    }
    
    return result
}
