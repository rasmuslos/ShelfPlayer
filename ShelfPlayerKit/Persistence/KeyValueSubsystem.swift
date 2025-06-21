//
//  KeyValue.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import SwiftData
import OSLog

typealias KeyValueEntity = SchemaV2.PersistedKeyValueEntity

extension PersistenceManager {
    @ModelActor
    public final actor KeyValueSubsystem: Sendable {
        private let logger = Logger(subsystem: "SatelliteGuardKit", category: "KeyValue")
        
        public subscript<T: Codable>(_ key: Key<T>) -> T? {
            guard let entity = entity(for: key) else {
                return nil
            }
            
            return value(for: entity, type: T.self)
        }
        private func value<T: Decodable>(for key: KeyValueEntity, type: T.Type) -> T? {
            do {
                return try JSONDecoder().decode(T.self, from: key.value)
            } catch {
                logger.error("Failed to decode \(T.self): \(error)")
                return nil
            }
        }
        
        public func set<Value>(_ key: Key<Value>, _ value: Value?) throws {
            let identifier = key.identifier
            let existing = try? modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate<KeyValueEntity> { $0.key == identifier })).first
            
            if let value {
                let data = try JSONEncoder().encode(value)
                
                if let existing {
                    existing.value = data
                } else {
                    let entity = KeyValueEntity(key: identifier, cluster: key.cluster, value: data, isCachePurgeable: key.isCachePurgeable)
                    modelContext.insert(entity)
                }
            } else if existing != nil {
                try modelContext.delete(model: KeyValueEntity.self, where: #Predicate { $0.key == identifier })
            }
            
            try modelContext.save()
        }
        
        func remove(itemID: ItemIdentifier) {
            do {
                try modelContext.delete(model: KeyValueEntity.self, where: #Predicate {
                    $0.key.contains(itemID.description) || $0.cluster.contains(itemID.description)
                })
            } catch {
                logger.error("Failed to remove related key value pairs for itemID \(itemID): \(error)")
            }
        }
        func remove(connectionID: ItemIdentifier.ConnectionID) {
            do {
                try modelContext.delete(model: KeyValueEntity.self, where: #Predicate {
                    $0.key.contains(connectionID) || $0.cluster.contains(connectionID)
                })
            } catch {
                logger.error("Failed to remove related key value pairs for connection \(connectionID): \(error)")
            }
        }
        public func remove(cluster: String) throws {
            try modelContext.delete(model: KeyValueEntity.self, where: #Predicate { $0.cluster == cluster })
            try modelContext.save()
        }
        
        func reset() throws {
            try modelContext.delete(model: KeyValueEntity.self)
            try modelContext.save()
        }
        func purgeCached() throws {
            try modelContext.delete(model: KeyValueEntity.self, where: #Predicate { $0.isCachePurgeable })
            try modelContext.save()
        }
        func purgeCached(itemID: ItemIdentifier) throws {
            try modelContext.delete(model: KeyValueEntity.self, where: #Predicate {
                $0.isCachePurgeable
                && ($0.key.contains(itemID.description) || $0.cluster.contains(itemID.description))
            })
            try modelContext.save()
        }
        
        private func entity<T>(for key: Key<T>) -> KeyValueEntity? {
            let identifier = key.identifier
            
            return try? modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate {
                $0.key == identifier
            })).first
        }
        public func entities<T: Decodable>(cluster: String, type: T.Type) -> [String: T] {
            do {
                let entities = try modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate { $0.cluster == cluster }))
                let mapped = entities.compactMap { entity -> (key: String, value: T)? in
                    guard let value = value(for: entity, type: T.self) else {
                        return nil
                    }
                    
                    return (entity.key, value)
                }
                
                return Dictionary(uniqueKeysWithValues: mapped)
            } catch {
                return [:]
            }
        }
        public func entityCount(cluster: String) -> Int {
            (try? modelContext.fetchCount(FetchDescriptor<KeyValueEntity>(predicate: #Predicate { $0.cluster == cluster }))) ?? 0
        }
        
        public struct Key<Value: Codable>: Sendable {
            public typealias Key = PersistenceManager.KeyValueSubsystem.Key
            
            public let identifier: String
            public let cluster: String
            public let isCachePurgeable: Bool
            
            public init(identifier: String, cluster: String, isCachePurgeable: Bool) {
                self.identifier = identifier
                self.cluster = cluster
                self.isCachePurgeable = isCachePurgeable
            }
        }
    }
}
