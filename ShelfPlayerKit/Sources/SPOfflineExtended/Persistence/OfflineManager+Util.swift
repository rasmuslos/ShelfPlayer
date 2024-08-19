//
//  OfflineManager+Reference.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData
import SPFoundation
import SPOffline

// MARK: Chapters

extension OfflineManager {
    @MainActor
    func storeChapters(_ chapters: PlayableItem.Chapters, itemId: String) async {
        for chapter in chapters {
            let offlineChapter = OfflineChapter(
                id: chapter.id,
                itemId: itemId,
                start: chapter.start,
                end: chapter.end,
                title: chapter.title)
            
            PersistenceManager.shared.modelContainer.mainContext.insert(offlineChapter)
        }
    }
    
    @MainActor
    public func getChapters(itemId: String) -> PlayableItem.Chapters {
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
    
    @MainActor
    func deleteChapters(itemId: String) {
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflineChapter.self, where: #Predicate { $0.itemId == itemId })
    }
}

// MARK: Error

extension OfflineManager {
    enum OfflineError: Error {
        case missing
        case fetchFailed
    }
}
