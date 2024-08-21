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

extension OfflineManager {
    public func chapters(itemId: String) throws -> [PlayableItem.Chapter] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<OfflineChapter>(predicate: #Predicate { $0.itemId == itemId })
        let chapters = try context.fetch(descriptor)
        
        return chapters.map { PlayableItem.Chapter(id: $0.id, start: $0.start, end: $0.end, title: $0.title) }
    }
    
    internal func storeChapters(_ chapters: [PlayableItem.Chapter], itemId: String, context: ModelContext) {
        for chapter in chapters {
            let offlineChapter = OfflineChapter(
                id: chapter.id,
                itemId: itemId,
                start: chapter.start,
                end: chapter.end,
                title: chapter.title)
            
            context.insert(offlineChapter)
        }
    }
    
    internal func removeChapters(itemId: String, context: ModelContext) throws {
        try context.delete(model: OfflineChapter.self, where: #Predicate { $0.itemId == itemId })
    }
}
