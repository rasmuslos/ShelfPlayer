//
//  File.swift
//
//
//  Created by Rasmus Krämer on 16.01.24.
//

import Foundation
import SwiftData
import SPFoundation
import SPPersistence

// MARK: Internal (Helper)

internal extension OfflineManager {
    func offlineTrack(downloadIdentifier: Int, context: ModelContext) throws -> OfflineTrack {
        var descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.downloadReference == downloadIdentifier })
        descriptor.fetchLimit = 1
        
        if let track = try context.fetch(descriptor).first {
            return track
        }
        
        throw OfflineError.missing
    }
    
    func offlineTracks(context: ModelContext) throws -> [OfflineTrack] {
        try context.fetch(.init())
    }
    
    func offlineTracks(parentId: String, context: ModelContext) throws -> [OfflineTrack] {
        try context.fetch(FetchDescriptor(predicate: #Predicate { $0.parentId == parentId }))
    }
    
    func download(tracks: [PlayableItem.AudioTrack], for itemId: String, type: OfflineTrack.ParentType, context: ModelContext) {
        guard tracks.reduce(true, { $0 && $1.fileExtension != nil }) else {
            switch type {
            case .audiobook:
                remove(audiobookId: itemId)
            case .episode:
                remove(episodeId: itemId)
            }
            
            return
        }
        
        for track in tracks {
            let offlineTrack = OfflineTrack(
                id: "\(itemId)_\(track.index)",
                parentId: itemId,
                index: track.index,
                fileExtension: track.fileExtension!,
                offset: track.offset,
                duration: track.duration,
                type: type)
            
            context.insert(offlineTrack)
            
            let task = DownloadManager.shared.download(track: track)
            offlineTrack.downloadReference = task.taskIdentifier
            
            task.resume()
        }
        
        DownloadManager.shared.startProgressTracking(itemId: itemId, trackCount: tracks.count)
    }
    
    func remove(track: OfflineTrack, context: ModelContext) {
        DownloadManager.shared.remove(track: track)
        context.delete(track)
    }
}


// MARK: Public

public extension OfflineManager {
    func audioTracks(parentId: String) throws -> [PlayableItem.AudioTrack] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<OfflineTrack>(predicate: #Predicate { $0.parentId == parentId })
        
        return try context.fetch(descriptor).map(PlayableItem.AudioTrack.init)
    }
    
    func url(for track: PlayableItem.AudioTrack, itemId: String) throws -> URL {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let tracks = try offlineTracks(parentId: itemId, context: context)
        
        if let track = tracks.filter({ $0.index == track.index }).first {
            return DownloadManager.shared.trackURL(track: track)
        }
        
        throw OfflineError.missing
    }
    
    func offlineStatus(parentId: String) -> OfflineStatus {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        guard let tracks = try? offlineTracks(parentId: parentId, context: context), !tracks.isEmpty else {
            return .none
        }
        
        return tracks.reduce(true) { $1.isDownloaded ? $0 : false } ? .downloaded : .working
    }
    
    enum OfflineStatus: Int {
        case none = 0
        case working = 1
        case downloaded = 2
    }
}
