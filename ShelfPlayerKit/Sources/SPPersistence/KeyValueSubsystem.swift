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
                        let entity = KeyValueEntity(key: key.identifier, value: data)
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
        
        public func bulkDelete<T>(keys: [Key<T>]) throws where T: Decodable {
            for key in keys {
                guard let entity = entity(for: key) else {
                    continue
                }
                
                modelContext.delete(entity)
            }
            
            try modelContext.save()
        }
        
        func reset() throws {
            try modelContext.delete(model: KeyValueEntity.self)
        }
        
        private func entity<T>(for key: Key<T>) -> KeyValueEntity? where T: Decodable {
            let identifier = key.identifier
            return try? modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate { $0.key == identifier })).first
        }
        
        public struct Key<Value: Codable>: Sendable {
            public typealias Key = PersistenceManager.KeyValueSubsystem.Key
            
            let identifier: String
            
            init(_ identifier: String) {
                self.identifier = identifier
            }
        }
    }
}

public extension PersistenceManager.KeyValueSubsystem.Key {
    static func hideFromContinueListening(connectionID: ItemIdentifier.ConnectionID) -> Key<Set<String>> {
        .init("hideFromContinueListening_\(connectionID)")
    }
    
    static func assetFailedAttempts(assetID: UUID) -> Key<Int> {
        .init("assetFailedAttempts_\(assetID)")
    }
    static func cachedDownloadStatus(itemID: ItemIdentifier) -> Key<PersistenceManager.DownloadSubsystem.DownloadStatus> {
        .init("cachedDownloadStatus_\(itemID)")
    }
    
    static func coverURLCache(itemID: ItemIdentifier) -> Key<URL> {
        .init("coverURLCache_\(itemID)")
    }
}
