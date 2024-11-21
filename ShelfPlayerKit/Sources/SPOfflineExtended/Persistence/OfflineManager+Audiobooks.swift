//
//  OfflineManager+Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData
import SPFoundation
import SPNetwork
import SPOffline

// MARK: Internal (Helper)

internal extension OfflineManager {
    func offlineAudiobook(audiobookId: String, context: ModelContext) throws -> OfflineAudiobook {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAudiobook> { $0.id == audiobookId })
        descriptor.fetchLimit = 1
        
        if let audiobook = try context.fetch(descriptor).first {
            return audiobook
        }
        
        throw OfflineError.missing
    }
    
    func offlineAudiobooks(context: ModelContext) throws -> [OfflineAudiobook] {
        try context.fetch(.init())
    }
}

// MARK: Public

public extension OfflineManager {
    func audiobook(audiobookId: String) throws -> Audiobook {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        return try Audiobook(audiobook: offlineAudiobook(audiobookId: audiobookId, context: context))
    }
    
    func audiobooks() throws -> [Audiobook] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        return try offlineAudiobooks(context: context).map(Audiobook.init)
    }
    
    func downloading() throws -> [Audiobook] {
        try audiobooks().filter { offlineStatus(parentId: $0.id) == .working }
    }
    
    func audiobooks(query: String) throws -> [Audiobook] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<OfflineAudiobook>(predicate: #Predicate { $0.name.localizedStandardContains(query) })
        let result = try context.fetch(descriptor)
        
        return result.map(Audiobook.init)
    }
    
    func download(audiobookId: String) async throws {
        let (audiobook, tracks, chapters) = try await AudiobookshelfClient.shared.item(itemId: audiobookId, episodeId: nil)
        guard let audiobook = audiobook as? Audiobook else {
            throw OfflineError.fetchFailed
        }
        
        try await DownloadManager.shared.download(cover: audiobook.cover, itemId: audiobook.id)
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        guard ((try? offlineAudiobook(audiobookId: audiobookId, context: context)) ?? nil) == nil else {
            logger.error("Audiobook is already downloaded")
            throw OfflineError.existing
        }
        
        let offlineAudiobook = OfflineAudiobook(
            id: audiobook.id,
            libraryId: audiobook.libraryID,
            name: audiobook.name,
            author: audiobook.author,
            overview: audiobook.description,
            genres: audiobook.genres,
            addedAt: audiobook.addedAt,
            released: audiobook.released,
            size: audiobook.size,
            narrator: audiobook.narrator,
            seriesName: audiobook.seriesName,
            duration: audiobook.duration,
            explicit: audiobook.explicit,
            abridged: audiobook.abridged)
        
        context.insert(offlineAudiobook)
        
        storeChapters(chapters, itemId: audiobook.id, context: context)
        download(tracks: tracks, for: audiobook.id, type: .audiobook, context: context)
        
        try context.save()
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: audiobook.id)
    }
    
    func remove(audiobookId: String) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        try? DownloadManager.shared.deleteImage(identifiedBy: audiobookId)
        try? removeChapters(itemId: audiobookId, context: context)
        
        if let audiobook = try? offlineAudiobook(audiobookId: audiobookId, context: context) {
            context.delete(audiobook)
        }
        
        if let tracks = try? offlineTracks(parentId: audiobookId, context: context) {
            for track in tracks {
                if let taskID = track.downloadReference {
                    DownloadManager.shared.cancel(taskID: taskID)
                }
                
                remove(track: track, context: context)
            }
        }
        
        try? context.save()
        
        removePlaybackSpeedOverride(for: audiobookId, episodeID: nil)
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: audiobookId)
    }
}
