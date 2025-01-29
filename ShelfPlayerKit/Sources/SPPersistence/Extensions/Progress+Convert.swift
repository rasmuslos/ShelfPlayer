//
//  Progress+Convert.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import SPFoundation

extension ProgressEntity {
    init(persistedEntity: PersistedProgress) {
        self.init(id: persistedEntity.id,
                  connectionID: persistedEntity.connectionID,
                  primaryID: persistedEntity.primaryID,
                  groupingID: persistedEntity.groupingID,
                  progress: persistedEntity.progress,
                  duration: persistedEntity.duration,
                  currentTime: persistedEntity.currentTime,
                  startedAt: persistedEntity.startedAt,
                  lastUpdate: persistedEntity.lastUpdate,
                  finishedAt: persistedEntity.finishedAt)
    }
}
