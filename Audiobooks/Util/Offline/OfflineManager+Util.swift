//
//  OfflineManager+Reference.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

// MARK: Reference

extension OfflineManager {
    @MainActor
    func getReferenceByDownloadTaskId(_ taskId: Int) -> DownloadReference? {
        var reference = FetchDescriptor<DownloadReference>(predicate: #Predicate { $0.downloadTask == taskId })
        reference.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(reference).first
    }
    
    @MainActor
    func getReferenceByReference(_ reference: String) -> DownloadReference? {
        var referenceObj = FetchDescriptor<DownloadReference>(predicate: #Predicate { $0.reference == reference })
        referenceObj.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(referenceObj).first
    }
}

// MARK: Chapters

extension OfflineManager {
    @MainActor
    func getChapters(itemId: String) -> PlayableItem.Chapters {
        let chapters = FetchDescriptor<OfflineChapter>(predicate: #Predicate { $0.itemId == itemId })
        
        if let chapters = try? PersistenceManager.shared.modelContainer.mainContext.fetch(chapters) {
            return chapters.map {
                PlayableItem.Chapter(
                    id: $0.id,
                    start: $0.start,
                    end: $0.end,
                    title: $0.title)
            }
        }
        
        return []
    }
}
