//
//  DownloadManager+Handler.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tmpLocation = documentsURL.appending(path: String(downloadTask.taskIdentifier))
        do {
            try? FileManager.default.removeItem(at: tmpLocation)
            try FileManager.default.moveItem(at: location, to: tmpLocation)
        } catch {
            logger.fault("Error while moving tmp file: \(error.localizedDescription)")
            return
        }
        
        Task.detached { @MainActor [self] in
            if let reference = OfflineManager.shared.getReferenceByDownloadTaskId(downloadTask.taskIdentifier) {
                if let track = OfflineManager.shared.getAudiobookTrackById(reference.reference) {
                    let destination = getAudiobookTrackUrl(trackId: track.id)
                    
                    do {
                        try? FileManager.default.removeItem(at: destination)
                        try FileManager.default.moveItem(at: tmpLocation, to: destination)
                        track.downloadCompleted = true
                        
                        PersistenceManager.shared.modelContainer.mainContext.delete(reference)
                        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: track.audiobookId)
                        
                        logger.info("Download track finished: \(track.id)")
                    } catch {
                        try? FileManager.default.removeItem(at: tmpLocation)
                        try? OfflineManager.shared.deleteAudiobook(audiobookId: track.audiobookId)
                        
                        logger.fault("Error while moving track \(track.id): \(error.localizedDescription)")
                    }
                    
                    return
                } else if let episode = OfflineManager.shared.getEpisodeById(reference.reference) {
                    let destination = getEpisodeUrl(episodeId: episode.id)
                    
                    do {
                        try? FileManager.default.removeItem(at: destination)
                        try FileManager.default.moveItem(at: tmpLocation, to: destination)
                        episode.downloadCompleted = true
                        
                        PersistenceManager.shared.modelContainer.mainContext.delete(reference)
                        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: episode.id)
                        
                        logger.info("Download episode finished: \(episode.id) (\(episode.name))")
                    } catch {
                        try? FileManager.default.removeItem(at: tmpLocation)
                        try? OfflineManager.shared.deleteEpisode(episodeId: episode.id)
                        
                        logger.fault("Error while moving episode \(episode.id) (\(episode.name)): \(error.localizedDescription)")
                    }
                    
                    return
                }
            }
            
            logger.fault("Unknown download finished")
            try? FileManager.default.removeItem(at: tmpLocation)
        }
    }
    
    // Error handling
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task.detached { @MainActor [self] in
                if let reference = OfflineManager.shared.getReferenceByDownloadTaskId(task.taskIdentifier) {
                    if let track = OfflineManager.shared.getAudiobookTrackById(reference.reference) {
                        try? OfflineManager.shared.deleteAudiobook(audiobookId: track.audiobookId)
                        logger.fault("Error while downloading track \(track.id): \(error.localizedDescription)")
                        
                        return
                    } else if let episode = OfflineManager.shared.getEpisodeById(reference.reference) {
                        try? OfflineManager.shared.deleteEpisode(episodeId: episode.id)
                        logger.fault("Error while downloading episode \(episode.id) (\(episode.name)): \(error.localizedDescription)")
                        
                        return
                    }
                }
                
                logger.fault("Error while downloading unknown track: \(error.localizedDescription)")
            }
        }
    }
}
