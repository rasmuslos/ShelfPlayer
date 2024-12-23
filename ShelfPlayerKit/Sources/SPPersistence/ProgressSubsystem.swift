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
        
        func sync(sessions payload: [SessionPayload]) async throws {
            do {
                let signpostID = signposter.makeSignpostID()
                let signpostState = signposter.beginInterval("sync", id: signpostID)
                
                logger.info("Initiating sync")
                
                try modelContext.save()
                let mapped = Dictionary(uniqueKeysWithValues: payload.map { ($0.id, $0) })
                
                signposter.emitEvent("mapIDs", id: signpostID)
                
                var pendingDeletion = [(id: String, serverID: String)]()
                var pendingCreation = [ProgressEntity]()
                var pendingUpdate = [ProgressEntity]()
                
                try modelContext.transaction {
                    try modelContext.enumerate(FetchDescriptor<PersistedProgress>()) { entity in
                        let id = entity.id
                        let payload = mapped[id]
                        
                        switch entity.status {
                        case .synchronised, .desynchronised:
                            guard let payload else {
                                pendingCreation.append(.init(persistedEntity: entity))
                                return
                            }
                            
                            let delta = Int(payload.updatedAt / 1000).distance(to: Int(entity.lastUpdate.timeIntervalSince1970))
                            
                            if delta == 0 && entity.status == .synchronised {
                                return
                            } else if delta > 0 {
                                entity.duration = payload.duration ?? 0
                                entity.currentTime = payload.currentTime ?? 0
                                
                                entity.progress = payload.progress ?? 0
                                
                                entity.startedAt = Date(timeIntervalSince1970: Double(payload.startedAt) / 1000)
                                entity.lastUpdate = Date(timeIntervalSince1970: Double(payload.updatedAt) / 1000)
                                
                                if let finishedAt = payload.finishedAt {
                                    entity.finishedAt = Date(timeIntervalSince1970: Double(finishedAt) / 1000)
                                } else {
                                    entity.finishedAt = nil
                                }
                            } else {
                                pendingUpdate.append(.init(persistedEntity: entity))
                            }
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
                    try? await ABSClient[serverID].deleteProgress(progressID: id)
                }
                
                signposter.emitEvent("delete", id: signpostID)
                
                let batch = pendingCreation + pendingUpdate
                
                logger.info("Batch updating \(batch.count) progress entities")
                
                
                
                signposter.emitEvent("batch", id: signpostID)
                
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
