//
//  OfflineManager+Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData
import SPBase
import SPOffline

public extension OfflineManager {
    @MainActor
    func getAudiobooks() throws -> [Audiobook] {
        try getOfflineAudiobooks().map(Audiobook.convertFromOffline)
    }
    
    @MainActor
    func getAudiobooks(query: String) throws -> [Audiobook] {
        let descriptor = FetchDescriptor<OfflineAudiobook>(predicate: #Predicate { $0.name.localizedStandardContains(query) })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).map(Audiobook.convertFromOffline)
    }
    
    @MainActor
    func getAudiobook(audiobookId: String) throws -> Audiobook {
        try Audiobook.convertFromOffline(audiobook: getOfflineAudiobook(audiobookId: audiobookId))
    }
    
    @MainActor
    func download(audiobookId: String) async throws {
        if (try? getOfflineAudiobook(audiobookId: audiobookId)) != nil {
            logger.error("Audiobook is already downloaded")
            return
        }
        
        let (audiobook, tracks, chapters) = try await AudiobookshelfClient.shared.getItem(itemId: audiobookId, episodeId: nil)
        guard let audiobook = audiobook as? Audiobook else { throw OfflineError.fetchFailed }
        
        let offlineAudiobook = OfflineAudiobook(
            id: audiobook.id,
            libraryId: audiobook.libraryId,
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
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineAudiobook)
        try await DownloadManager.shared.downloadImage(itemId: audiobook.id, image: audiobook.image)
        
        await storeChapters(chapters, itemId: audiobook.id)
        download(itemId: audiobook.id, tracks: tracks, type: .audiobook)
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: audiobook.id)
    }
    
    @MainActor
    func delete(audiobookId: String) {
        try? DownloadManager.shared.deleteImage(itemId: audiobookId)
        deleteChapters(itemId: audiobookId)
        
        if let audiobook = try? getOfflineAudiobook(audiobookId: audiobookId) {
            PersistenceManager.shared.modelContainer.mainContext.delete(audiobook)
        }
        if let tracks = try? getOfflineTracks(parentId: audiobookId) {
            for track in tracks {
                delete(track: track)
            }
        }
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: audiobookId)
    }
}

extension OfflineManager {
    @MainActor
    func getOfflineAudiobook(audiobookId: String) throws -> OfflineAudiobook {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAudiobook> { $0.id == audiobookId })
        descriptor.fetchLimit = 1
        
        if let audiobook = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return audiobook
        }
        
        throw OfflineError.missing
    }
    
    @MainActor
    func getOfflineAudiobooks() throws -> [OfflineAudiobook] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor())
    }
}
