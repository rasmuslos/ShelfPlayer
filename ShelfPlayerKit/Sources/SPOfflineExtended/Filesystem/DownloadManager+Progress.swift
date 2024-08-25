//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 05.05.24.
//

import Foundation
import SPFoundation
import SPNetwork
import SPOffline

internal extension DownloadManager {
    private static let serialQueue = DispatchQueue(label: "io.rfk.shelfplayer.progress.serialQueue")
    
    func startProgressTracking(itemId: String, trackCount: Int) {
        Self.serialQueue.sync {
            AudiobookshelfClient.defaults.set(0.0, forKey: "downloadTotalProgress_\(itemId)")
            
            AudiobookshelfClient.defaults.set(trackCount, forKey: "downloadTrackCount_\(itemId)")
            AudiobookshelfClient.defaults.set(trackCount, forKey: "downloadTrackFinishedCount_\(itemId)")
        }
    }
    
    func stopProgressTracking(taskIdentifier: Int, itemId: String) {
        Self.serialQueue.sync {
            let finished = AudiobookshelfClient.defaults.integer(forKey: "downloadTrackFinishedCount_\(itemId)") + 1
            let trackCount = AudiobookshelfClient.defaults.integer(forKey: "downloadTrackCount_\(itemId)")
            
            if finished >= trackCount {
                AudiobookshelfClient.defaults.removeObject(forKey: "downloadTrackCount_\(itemId)")
                AudiobookshelfClient.defaults.removeObject(forKey: "downloadTotalProgress_\(itemId)")
                AudiobookshelfClient.defaults.removeObject(forKey: "downloadTrackFinishedCount_\(itemId)")
            } else {
                AudiobookshelfClient.defaults.set(finished, forKey: "downloadTrackFinishedCount_\(itemId)")
            }
            
            AudiobookshelfClient.defaults.removeObject(forKey: "downloadProgress_\(taskIdentifier)")
            NotificationCenter.default.post(name: OfflineManager.downloadProgressUpdatedNotification, object: nil)
        }
    }
    
    func abortProgressTracking(taskIdentifier: Int, itemId: String) {
        Self.serialQueue.sync {
            AudiobookshelfClient.defaults.removeObject(forKey: "downloadTrackCount_\(itemId)")
            AudiobookshelfClient.defaults.removeObject(forKey: "downloadTotalProgress_\(itemId)")
            AudiobookshelfClient.defaults.removeObject(forKey: "downloadTrackFinishedCount_\(itemId)")
            
            AudiobookshelfClient.defaults.removeObject(forKey: "downloadProgress_\(taskIdentifier)")
            NotificationCenter.default.post(name: OfflineManager.downloadProgressUpdatedNotification, object: nil)
        }
    }
    func abortProgressTracking(taskIdentifier: Int) {
        Self.serialQueue.sync {
            AudiobookshelfClient.defaults.removeObject(forKey: "downloadProgress_\(taskIdentifier)")
            NotificationCenter.default.post(name: OfflineManager.downloadProgressUpdatedNotification, object: nil)
        }
    }
    
    func updateProgress(taskIdentifier: Int, itemId: String, progress: Double) {
        Self.serialQueue.sync {
            let previous = max(AudiobookshelfClient.defaults.double(forKey: "downloadProgress_\(taskIdentifier)"), 0)
            let delta = progress - previous
            
            let totalProgress = AudiobookshelfClient.defaults.double(forKey: "downloadTotalProgress_\(itemId)")
            let taskCount = Double(AudiobookshelfClient.defaults.integer(forKey: "downloadTrackCount_\(itemId)"))
            
            let current = totalProgress + delta * (1 / taskCount)
            
            AudiobookshelfClient.defaults.set(current, forKey: "downloadTotalProgress_\(itemId)")
            AudiobookshelfClient.defaults.set(progress, forKey: "downloadProgress_\(taskIdentifier)")
            
            NotificationCenter.default.post(name: OfflineManager.downloadProgressUpdatedNotification, object: nil)
        }
    }
}
