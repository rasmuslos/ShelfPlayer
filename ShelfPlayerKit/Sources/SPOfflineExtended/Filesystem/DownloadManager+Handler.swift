//
//  DownloadManager+Handler.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData
import SPFoundation
import SPOffline

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tmpLocation = documentsURL.appending(path: String(downloadTask.taskIdentifier))
        
        do {
            try? FileManager.default.removeItem(at: tmpLocation)
            try FileManager.default.moveItem(at: location, to: tmpLocation)
        } catch {
            logger.fault("Error while moving tmp file: \(error.localizedDescription)")
            abortProgressTracking(taskIdentifier: downloadTask.taskIdentifier)
            
            return
        }
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        guard let track = try? OfflineManager.shared.offlineTrack(downloadIdentifier: downloadTask.taskIdentifier, context: context) else {
            logger.fault("Unknown download finished")
            
            try? FileManager.default.removeItem(at: tmpLocation)
            abortProgressTracking(taskIdentifier: downloadTask.taskIdentifier)
            
            return
        }
        
        stopProgressTracking(taskIdentifier: downloadTask.taskIdentifier, itemId: track.parentId)
        
        var destination = trackURL(track: track)
        try? destination.setResourceValues({
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            
            return values
        }())
        
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: tmpLocation, to: destination)
        } catch {
            try? FileManager.default.removeItem(at: tmpLocation)
            OfflineManager.shared.remove(track: track, context: context)
            
            logger.fault("Error while moving track \(track.id): \(error.localizedDescription)")
        }
        
        track.downloadReference = nil
        
        do {
            try context.save()
        } catch {
            logger.fault("Failed to save context after download finished: \(error.localizedDescription)")
        }
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: track.parentId)
        logger.info("Download track finished: \(track.id)")
    }
    
    // Progress tracking
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten _: Int64, totalBytesExpectedToWrite _: Int64) {
        guard let track = try? OfflineManager.shared.offlineTrack(downloadIdentifier: downloadTask.taskIdentifier, context: ModelContext(PersistenceManager.shared.modelContainer)) else {
            abortProgressTracking(taskIdentifier: downloadTask.taskIdentifier)
            return
        }
        
        updateProgress(taskIdentifier: downloadTask.taskIdentifier, itemId: track.parentId, progress: downloadTask.progress.fractionCompleted)
    }
    
    // Error handling
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            guard let track = try? OfflineManager.shared.offlineTrack(downloadIdentifier: task.taskIdentifier, context: ModelContext(PersistenceManager.shared.modelContainer)) else {
                logger.fault("Error while downloading unknown track: \(error.localizedDescription)")
                abortProgressTracking(taskIdentifier: task.taskIdentifier)
                
                return
            }
            
            if track.type == .audiobook {
                OfflineManager.shared.remove(audiobookId: track.parentId)
            } else if track.type == .episode {
                OfflineManager.shared.remove(episodeId: track.parentId)
            }
            
            logger.fault("Error while downloading track \(track.id): \(error.localizedDescription)")
            abortProgressTracking(taskIdentifier: task.taskIdentifier, itemId: track.parentId)
        }
    }
}
