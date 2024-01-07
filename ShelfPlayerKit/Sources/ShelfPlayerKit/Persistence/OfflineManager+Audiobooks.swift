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
    public func download(audiobook: Audiobook) async throws {
        if getAudiobook(audiobookId: audiobook.id) != nil {
            logger.error("Audiobook is already downloaded")
            return
        }
        
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
        
        let (tracks, chapters) = try await AudiobookshelfClient.shared.getAudiobookDownloadData(audiobook.id)
        try await DownloadManager.shared.downloadImage(itemId: audiobook.id, image: audiobook.image)
        
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
        }
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: audiobook.id)
    }
}

// MARK: Getter

extension OfflineManager {
    @MainActor
    func getAudiobook(audiobookId: String) -> OfflineAudiobook? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAudiobook> { $0.id == audiobookId })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    
    @MainActor
    func getAudiobook(trackId: String) -> OfflineAudiobookTrack? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineAudiobookTrack> { $0.id == trackId })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    
    @MainActor
    func getAudiobookTracks(audiobookId: String) throws -> [OfflineAudiobookTrack] {
        let descriptor = FetchDescriptor(predicate: #Predicate<OfflineAudiobookTrack> { $0.audiobookId == audiobookId })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
    }
    
    @MainActor
    func getAudiobookOfflineStatus(audiobookId: String) -> PlayableItem.OfflineStatus {
        if getAudiobook(audiobookId: audiobookId) != nil, let tracks = try? getAudiobookTracks(audiobookId: audiobookId) {
            return tracks.reduce(true, { $1.downloadCompleted ? $0 : false }) ? .downloaded : .working
        }
        
        return .none
    }
    
    @MainActor
    public func getAudiobooks() -> [Audiobook] {
        let descriptor = FetchDescriptor<OfflineAudiobook>()
        if let audiobooks = (try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor))?.map(Audiobook.convertFromOffline) {
            return audiobooks
        }
        
        return []
    }
    
    @MainActor
    public func getAudiobookDownloadData() throws -> [Audiobook: (Int, Int)] {
        let tracks = try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineAudiobookTrack>())
        var result = [Audiobook: (Int, Int)]()
        var audiobookIds = Set<String>()
        
        for track in tracks {
            audiobookIds.insert(track.audiobookId)
        }
        
        for audiobookId in audiobookIds {
            let audiobook = Audiobook.convertFromOffline(audiobook: getAudiobook(audiobookId: audiobookId)!)
            let tracks = tracks.filter { $0.audiobookId == audiobookId }
            
            result[audiobook] = (tracks.reduce(tracks.count, { $1.downloadCompleted ? $0 : $0 - 1 }), tracks.count)
        }
        
        return result
    }
}

// MARK: Delete

extension OfflineManager {
    @MainActor
    public func delete(audiobookId: String) throws {
        try DownloadManager.shared.deleteImage(itemId: audiobookId)
        
        if let audiobook = getAudiobook(audiobookId: audiobookId) {
            PersistenceManager.shared.modelContainer.mainContext.delete(audiobook)
        }
        if let tracks = try? getAudiobookTracks(audiobookId: audiobookId) {
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
