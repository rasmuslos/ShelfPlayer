//
//  DownloadManager+Handler.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SPBaseKit
import SPOfflineKit

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
            guard let track = try? OfflineManager.shared.getOfflineTrack(downloadReference: downloadTask.taskIdentifier) else {
                logger.fault("Unknown download finished")
                try? FileManager.default.removeItem(at: tmpLocation)
                
                return
            }
            
            let destination = getURL(track: track)
            
            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: tmpLocation, to: destination)
                
                track.downloadReference = nil
                NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: track.parentId)

                logger.info("Download track finished: \(track.id)")
            } catch {
                try? FileManager.default.removeItem(at: tmpLocation)
                OfflineManager.shared.delete(track: track)
                
                logger.fault("Error while moving track \(track.id): \(error.localizedDescription)")
            }
        }
    }
    
    // Error handling
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task.detached { @MainActor [self] in
                guard let track = try? OfflineManager.shared.getOfflineTrack(downloadReference: task.taskIdentifier) else {
                    logger.fault("Error while downloading unknown track: \(error.localizedDescription)")
                    return
                }
                
                if track.type == .audiobook {
                    OfflineManager.shared.delete(audiobookId: track.parentId)
                } else if track.type == .episode {
                    OfflineManager.shared.delete(episodeId: track.parentId)
                }
                
                logger.fault("Error while downloading track \(track.id): \(error.localizedDescription)")
            }
        }
    }
}
