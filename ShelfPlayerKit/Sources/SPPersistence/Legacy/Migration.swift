//
//  Migration.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SPNetwork
@preconcurrency import SwiftData

enum Migration: SchemaMigrationPlan {
    static var stages: [MigrationStage] {[
        migrateV1ToV2
    ]}
    
    static var schemas: [any VersionedSchema.Type] {[
        SchemaV1.self, SchemaV2.self
    ]}
    
    nonisolated(unsafe) static var v1Audiobooks = [SchemaV1.OfflineAudiobook]()
    
    static let migrateV1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            v1Audiobooks = (try? context.fetch(.init())) ?? []
        }, didMigrate: { context in
            fatalError("do this")
            let suite = AudiobookshelfClient.suite
            
            /*
            for v1Audiobook in v1Audiobooks {
                let audiobook = SchemaV2.PersistedAudiobook(
                    id: .init(primaryID: v1Audiobook.id, groupingID: nil, libraryID: v1Audiobook.libraryId, serverID: <#T##String#>, type: .audiobook),
                    name: v1Audiobook.name,
                    authors: v1Audiobook.author?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: ", ")
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? [],
                    overview: v1Audiobook.overview,
                    genres: v1Audiobook.genres,
                    addedAt: v1Audiobook.addedAt,
                    released: v1Audiobook.released,
                    size: v1Audiobook.size,
                    duration: v1Audiobook.duration,
                    subtitle: nil,
                    narrators: v1Audiobook.narrator?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: ", ")
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? [],
                    series: v1Audiobook.seriesName,
                    explicit: v1Audiobook.abridged,
                    abridged: v1Audiobook.abridged,
                    tracks: <#T##[SchemaV2.PersistedAudioTrack]#>)
            }
             */
        }
    )
}
