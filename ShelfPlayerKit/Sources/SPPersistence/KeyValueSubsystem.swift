//
//  KeyValue.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import SwiftData
import OSLog
import SPFoundation

typealias KeyValueEntity = SchemaV2.PersistedKeyValueEntity

extension PersistenceManager {
    @ModelActor
    public final actor KeyValueSubsystem: Sendable {
        private let logger = Logger(subsystem: "SatelliteGuardKit", category: "KeyValue")
        
        public subscript<Value: Codable>(_ key: Key<Value>) -> Value? {
            guard let entity = entity(for: key) else {
                return nil
            }
            
            do {
                return try JSONDecoder().decode(Value.self, from: entity.value)
            } catch {
                logger.error("Failed to decode \(Value.self): \(error)")
                return nil
            }
        }
        
        public func set<Value>(_ key: Key<Value>, _ value: Value?) throws {
            let identifier = key.identifier
            
            let predicate = #Predicate<KeyValueEntity> { $0.key == identifier }
            let descriptor = FetchDescriptor<KeyValueEntity>(predicate: predicate)
            
            let existing = try? modelContext.fetch(descriptor).first
            
            if let value {
                do {
                    let data = try JSONEncoder().encode(value)
                    
                    if let existing {
                        existing.value = data
                    } else {
                        let entity = KeyValueEntity(key: key.identifier, cluster: key.cluster, value: data, isCachePurgeable: key.isCachePurgeable)
                        modelContext.insert(entity)
                    }
                    
                    try modelContext.save()
                } catch {
                    logger.error("Failed to encode \(Value.self) or save: \(error)")
                    throw error
                }
            } else {
                if existing != nil {
                    try modelContext.delete(model: KeyValueEntity.self, where: #Predicate { $0.key == identifier })
                    try modelContext.save()
                }
            }
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
        func remove(cluster: String) throws {
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
        
        private func entity<T>(for key: Key<T>) -> KeyValueEntity? where T: Decodable {
            let identifier = key.identifier
            return try? modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate { $0.key == identifier })).first
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
