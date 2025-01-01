//
//  Progress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import OSLog
import SwiftData
import RFNotifications
import SPFoundation
import SPNetwork

typealias PersistedProgress = SchemaV2.PersistedProgress

extension PersistenceManager {
    public final actor ProgressSubsystem: ModelActor {
        public nonisolated let modelExecutor: any SwiftData.ModelExecutor
        public nonisolated let modelContainer: SwiftData.ModelContainer
        
        let logger: Logger
        let signposter: OSSignposter

        public init(modelContainer: SwiftData.ModelContainer) {
            let modelContext = ModelContext(modelContainer)
            
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
            
            logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Progress")
            signposter = .init(logger: logger)
        }
        
        /// Insert changes into the database and notify the server of pending updates
        ///
        /// This function will:
        /// 1. update or delete existing progress entities
        /// 2. send detected differences to server
        /// 3. create missing local entities
        func sync(sessions payload: [ProgressPayload], serverID: ItemIdentifier.ServerID) async throws {
            do {
                let signpostID = signposter.makeSignpostID()
                let signpostState = signposter.beginInterval("sync", id: signpostID)
                
                logger.info("Initiating sync")
                
                try modelContext.save()
                
                signposter.emitEvent("mapIDs", id: signpostID)
                
                var pendingDeletion = [(id: String, serverID: String)]()
                var pendingCreation = [ProgressEntity]()
                var pendingUpdate = [ProgressEntity]()
                
                try modelContext.transaction {
                    try modelContext.enumerate(FetchDescriptor<PersistedProgress>()) { entity in
                        let id = entity.id
                        let payload = payload.first(where: { $0.id == id })
                        
                        switch entity.status {
                        case .synchronized, .desynchronized:
                            guard let payload else {
                                if entity.status == .desynchronized {
                                    pendingCreation.append(.init(persistedEntity: entity))
                                    return
                                } else {
                                    modelContext.delete(entity)
                                    return
                                }
                            }
                            
                            guard let lastUpdate = payload.lastUpdate else {
                                pendingUpdate.append(.init(persistedEntity: entity))
                                return
                            }
                            
                            let delta = Int(lastUpdate / 1000).distance(to: Int(entity.lastUpdate.timeIntervalSince1970))
                            
                            if delta == 0 && entity.status == .synchronized {
                                return
                            }
                            
                            if delta < 0 {
                                pendingUpdate.append(.init(persistedEntity: entity))
                                return
                            }
                            
                            entity.duration = payload.duration ?? 0
                            entity.currentTime = payload.currentTime ?? 0
                            
                            entity.progress = payload.progress ?? 0
                            
                            if let startedAt = payload.startedAt {
                                entity.startedAt = Date(timeIntervalSince1970: Double(startedAt) / 1000)
                            } else {
                                entity.startedAt = nil
                            }
                            
                            if let lastUpdate = payload.lastUpdate {
                                entity.lastUpdate = Date(timeIntervalSince1970: Double(lastUpdate) / 1000)
                            } else {
                                entity.lastUpdate = .now
                            }
                            
                            if let finishedAt = payload.finishedAt {
                                entity.finishedAt = Date(timeIntervalSince1970: Double(finishedAt) / 1000)
                            } else {
                                entity.finishedAt = nil
                            }
                            
                            entity.status = .synchronized
                        case .tombstone:
                            if payload != nil {
                                pendingDeletion.append((id, entity.itemID.serverID))
                            }
                            
                            modelContext.delete(entity)
                        }
                    }
                }
                
                signposter.emitEvent("transaction", id: signpostID)
                
                logger.info("Deleting \(pendingDeletion.count) progress entities")
                
                for (id, serverID) in pendingDeletion {
                    try? await ABSClient[serverID].delete(progressID: id)
                }
                
                signposter.emitEvent("delete", id: signpostID)
                
                let batch = pendingCreation + pendingUpdate
                let grouped = Dictionary(batch.map { ($0.itemID.serverID, [$0]) }, uniquingKeysWith: +)
                
                logger.info("Batch updating \(batch.count) progress entities from \(grouped.count) servers")
                
                for (serverID, entities) in grouped {
                    try await ABSClient[serverID].batchUpdate(progress: entities)
                }
                
                signposter.emitEvent("batch", id: signpostID)
                
                try modelContext.transaction {
                    let identifiers = try modelContext.fetchIdentifiers(FetchDescriptor<PersistedProgress>()) as! [String]
                    let remaining = payload.filter { !identifiers.contains($0.id) }
                    
                    for payload in remaining {
                        let entity = PersistedProgress(
                            id: payload.id,
                            itemID: .init(primaryID: payload.episodeId ?? payload.libraryItemId,
                                          groupingID: payload.episodeId != nil ? payload.libraryItemId : nil,
                                          libraryID: "_",
                                          serverID: serverID,
                                          type: payload.episodeId != nil ? .episode : .audiobook),
                            progress: payload.progress ?? 0,
                            duration: payload.duration ?? 0,
                            currentTime: payload.currentTime ?? 0,
                            startedAt: payload.startedAt != nil ? Date(timeIntervalSince1970: Double(payload.startedAt!) / 1000) : nil,
                            lastUpdate: payload.lastUpdate != nil ? Date(timeIntervalSince1970: Double(payload.lastUpdate!) / 1000) : .now,
                            finishedAt: payload.lastUpdate != nil ? Date(timeIntervalSince1970: Double(payload.lastUpdate!) / 1000) : nil,
                            status: .synchronized)
                        
                        modelContext.insert(entity)
                    }
                }
                
                signposter.emitEvent("cleanup", id: signpostID)
                
                try modelContext.save()
                
                signposter.endInterval("sync", signpostState)
            } catch {
                logger.error("Error while syncing progress: \(error)")
                
                modelContext.rollback()
                try modelContext.save()
                
                throw error
            }
        }
    }
}

extension PersistenceManager.ProgressSubsystem {
    func delete(_ entity: PersistedProgress) async throws {
        do {
            try await ABSClient[entity.itemID.serverID].delete(progressID: entity.id)
        }
        
        let id = entity.id
        
        try modelContext.delete(model: PersistedProgress.self, where: #Predicate {
            $0.id == id
        })
    }
}
public extension PersistenceManager.ProgressSubsystem {
    subscript(_ itemID: ItemIdentifier) -> ProgressEntity {
        let itemID = itemID
        var fetchDescriptor = FetchDescriptor<PersistedProgress>(predicate: #Predicate {
            $0.itemID == itemID
        })
        fetchDescriptor.includePendingChanges = true
        
        // Return existing
        
        do {
            let entities = try modelContext.fetch(fetchDescriptor)
            
            if !entities.isEmpty {
                if entities.count != 1 {
                    logger.error("Found \(entities.count) progress entities for \(itemID)")
                    
                    var sorted = entities.sorted { $0.lastUpdate > $1.lastUpdate }
                    sorted.removeFirst()
                    
                    for entity in sorted {
                        Task {
                            try await delete(entity)
                        }
                    }
                }
                
                return .init(persistedEntity: entities.first!)
            }
        } catch {
            logger.error("Error fetching progress for \(itemID): \(error)")
        }
        
        // Create new
        
        logger.error("Missing progress for \(itemID)")
        
        return .missing(itemID)
    }
}
