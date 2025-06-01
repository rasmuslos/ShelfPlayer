//
//  ItemEntity.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Foundation
import AppIntents

public struct ItemEntity: AppEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.entity.item", numericFormat: "intent.entity.item \(placeholder: .int)", synonyms: [
        "intent.entity.item.audiobook",
        "intent.entity.item.podcast",
    ])
    public static let defaultQuery = ItemEntityQuery()
    
    public let item: Item
    public let imageData: Data?
    
    init(item: Item) {
        self.item = item
        imageData = nil
    }
    init(item: Item) async {
        self.item = item
        imageData = await item.id.data(size: .regular)
    }
    
    public var id: ItemIdentifier {
        item.id
    }
    public var displayRepresentation: DisplayRepresentation {
        let image: DisplayRepresentation.Image?
        
        if let imageData {
            image = .init(data: imageData, displayStyle: .default)
        } else {
            image = nil
        }
        
        return .init(title: "\(item.name)", subtitle: "\(item.authors.formatted(.list(type: .and)))", image: image)
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
        var result: [ItemEntity] = []
        
        for item in await ShelfPlayerKit.listenNowItems {
            result.append(await ItemEntity(item: item))
        }
        
        return result
    }
}

extension ItemEntityQuery: EntityStringQuery {
    public func entities(matching string: String) async throws -> [ItemEntity] {
        []
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
