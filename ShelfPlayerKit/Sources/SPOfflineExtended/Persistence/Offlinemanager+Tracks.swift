//
//  File.swift
//
//
//  Created by Rasmus Krämer on 16.01.24.
//

import Foundation
import SwiftData
import SPBase
import SPOffline

public extension OfflineManager {
    typealias DownloadStatus = ([Audiobook: (Int, Int)], [Podcast: (Int, Int)])
    
    @MainActor
    func getDownloadStatus() async throws -> DownloadStatus {
        let tracks = try getOfflineTracks()
        var episodeIds = Set<String>()
        var audiobookIds = Set<String>()
        
        for track in tracks {
            switch track.type {
            case .episode:
                episodeIds.insert(track.parentId)
                break
            case .audiobook:
                audiobookIds.insert(track.parentId)
                break
            }
        }
        
        let episodes = try episodeIds.map(getOfflineEpisode)
        let audiobooks = try audiobookIds.map(getOfflineAudiobook)
        
        var podcasts = Set<OfflinePodcast>()
        
        for episode in episodes {
            podcasts.insert(episode.podcast)
        }
        
        var audiobookData = [Audiobook: (Int, Int)]()
        audiobooks.forEach { @MainActor audiobook in
            let tracks = tracks.filter { $0.parentId == audiobook.id }
            audiobookData[Audiobook.convertFromOffline(audiobook: audiobook)] = (tracks.filter(isDownloadFinished).count, tracks.count)
        }
        
        var podcastsData = [Podcast: (Int, Int)]()
        podcasts.forEach { @MainActor podcast in
            let episodes = episodes.filter { $0.podcast.id == podcast.id }
            podcastsData[Podcast.convertFromOffline(podcast: podcast)] = (episodes.filter { isDownloadFinished(episodeId: $0.id) }.count, episodes.count)
        }
        
        return (audiobookData, podcastsData)
    }
    
    @MainActor
    func getTracks(parentId: String) throws -> PlayableItem.AudioTracks {
        let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.parentId == parentId })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).map(PlayableItem.convertTrackFromOffline)
    }
    
    @MainActor
    func getTrack(itemId: String, track: PlayableItem.AudioTrack) throws -> URL {
        let tracks = try getOfflineTracks(parentId: itemId)
        
        if let track = tracks.filter({ $0.index == track.index }).first {
            return DownloadManager.shared.getURL(track: track)
        }
        
        throw OfflineError.missing
    }
    
    @MainActor
    func getOfflineStatus(parentId: String) -> ItemOfflineTracker.OfflineStatus {
        do {
            let tracks = try getOfflineTracks(parentId: parentId)
            
            if tracks.isEmpty {
                return .none
            }
            
            return tracks.reduce(true) { isDownloadFinished(track: $1) ? $0 : false } ? .downloaded : .working
        } catch {
            return .none
        }
    }
}

extension OfflineManager {
    @MainActor
    func getOfflineTrack(downloadReference: Int) throws -> OfflineTrack {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadReference == downloadReference })
        descriptor.fetchLimit = 1
        
        if let track = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return track
        }
        
        throw OfflineError.missing
    }
    
    @MainActor
    func getOfflineTracks() throws -> [OfflineTrack] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor())
    }
    
    @MainActor
    func getOfflineTracks(parentId: String) throws -> [OfflineTrack] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor(predicate: #Predicate { $0.parentId == parentId }))
    }
    
    @MainActor
    func isDownloadFinished(track: OfflineTrack) -> Bool {
        track.downloadReference == nil
    }
    
    @MainActor
    func download(itemId: String, tracks: PlayableItem.AudioTracks, type: OfflineTrack.ParentType) {
        for track in tracks {
            let offlineTrack = OfflineTrack(
                id: "\(itemId)_\(track.index)",
                parentId: itemId,
                index: track.index,
                fileExtension: track.fileExtension,
                offset: track.offset,
                duration: track.duration,
                type: type)
            
            PersistenceManager.shared.modelContainer.mainContext.insert(offlineTrack)
            
            let task = DownloadManager.shared.download(track: track)
            offlineTrack.downloadReference = task.taskIdentifier
            
            task.resume()
        }
        
        DownloadManager.shared.startProgressTracking(itemId: itemId, trackCount: tracks.count)
    }
    
    @MainActor
    func delete(track: OfflineTrack) {
        DownloadManager.shared.delete(track: track)
        PersistenceManager.shared.modelContainer.mainContext.delete(track)
    }
}
