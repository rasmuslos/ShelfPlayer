//
//  OfflineManager+Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

// MARK: Download

extension OfflineManager {
    @MainActor
    func downloadAudiobook(_ audiobook: Audiobook) async throws {
        if getAudiobookById(audiobook.id) != nil {
            logger.error("Audiobook is already downloaded")
            return
        }
        
        let (tracks, chapters) = try await AudiobookshelfClient.shared.getAudiobookDownloadData(audiobook.id)
        try await DownloadManager.shared.downloadImage(itemId: audiobook.id, image: audiobook.image)
        
        let offlineAudiobook = OfflineAudiobook(
            id: audiobook.id,
            libraryId: audiobook.libraryId,
            name: audiobook.name,
            author: audiobook.author,
            overview: audiobook.description,
            genres: [],
            addedAt: audiobook.addedAt,
            released: audiobook.released,
            size: audiobook.size,
            narrator: audiobook.narrator,
            seriesName: audiobook.series.audiobookSeriesName,
            duration: audiobook.duration,
            explicit: audiobook.explicit,
            abridged: audiobook.abridged)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineAudiobook)
        
        await storeChapters(chapters, itemId: audiobook.id)
        
        for track in tracks {
            let offlineTrack = OfflineAudiobookTrack(
                id: "\(audiobook.id)_\(track.index)",
                audiobookId: audiobook.id,
                index: track.index,
                offset: track.offset,
                duration: track.duration)
            
            let reference = DownloadReference(reference: offlineTrack.id, type: .audiobook)
            
            PersistenceManager.shared.modelContainer.mainContext.insert(offlineTrack)
            PersistenceManager.shared.modelContainer.mainContext.insert(reference)
            
            let task = DownloadManager.shared.downloadTrack(track: track)
            
            reference.downloadTask = task.taskIdentifier
            task.resume()
        }
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: audiobook.id)
    }
}

// MARK: Getter

extension OfflineManager {
    @MainActor
    func getAudiobookById(_ audiobookId: String) -> OfflineAudiobook? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAudiobook> { $0.id == audiobookId })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    
    @MainActor
    func getAudiobookTrackById(_ trackId: String) -> OfflineAudiobookTrack? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAudiobookTrack> { $0.id == trackId })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    
    @MainActor
    func getAudiobookTracksByAudiobookId(_ audiobookId: String) throws -> [OfflineAudiobookTrack] {
        let descriptor = FetchDescriptor(predicate: #Predicate<OfflineAudiobookTrack> { $0.audiobookId == audiobookId })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
    }
    
    @MainActor
    func getAudiobookOfflineStatus(audiobookId: String) -> PlayableItem.OfflineStatus {
        if getAudiobookById(audiobookId) != nil, let tracks = try? getAudiobookTracksByAudiobookId(audiobookId) {
            return tracks.reduce(true, { $1.downloadCompleted ? $0 : false }) ? .downloaded : .working
        }
        
        return .none
    }
    
    @MainActor
    func getAllAudiobooks() -> [OfflineAudiobook] {
        let descriptor = FetchDescriptor<OfflineAudiobook>()
        return (try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)) ?? []
    }
}

// MARK: Delete

extension OfflineManager {
    @MainActor
    func deleteAudiobook(audiobookId: String) throws {
        try DownloadManager.shared.deleteImage(itemId: audiobookId)
        
        if let audiobook = getAudiobookById(audiobookId) {
            PersistenceManager.shared.modelContainer.mainContext.delete(audiobook)
        }
        if let tracks = try? getAudiobookTracksByAudiobookId(audiobookId) {
            for track in tracks {
                deleteAudiobookTrack(track: track)
            }
        }
        
        try deleteChapters(itemId: audiobookId)
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: audiobookId)
    }
    
    @MainActor
    func deleteAudiobookTrack(track: OfflineAudiobookTrack) {
        if let reference = getReferenceByReference(track.id) {
            PersistenceManager.shared.modelContainer.mainContext.delete(reference)
        }
        
        DownloadManager.shared.deleteAudiobookTrack(trackId: track.id)
        PersistenceManager.shared.modelContainer.mainContext.delete(track)
    }
}
