//
//  BackgroundTaskHandler.swift
//  iOS
//
//  Created by Rasmus Krämer on 09.02.24.
//

import OSLog
import Defaults
import Foundation
import BackgroundTasks
import UserNotifications
import ShelfPlayerKit
import SPPlayback

internal struct BackgroundTaskHandler {
    static let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "Background-Refresh")
}

internal extension BackgroundTaskHandler {
    static func handle(task: BGTask) {
        let backgroundTask = Task.detached {
            do {
                try await Self.updateDownloads()
                
                task.setTaskCompleted(success: true)
                submitTask()
            } catch {
                task.setTaskCompleted(success: false)
                submitTask(failed: true)
            }
        }
        
        task.expirationHandler = {
            backgroundTask.cancel()
        }
    }
}
 
internal extension BackgroundTaskHandler {
    static func updateDownloads() async throws {
        guard !NetworkMonitor.isRouteLimited else { return }
        
        let configurations = try OfflineManager.shared.getConfigurations(active: true)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for configuration in configurations {
                group.addTask {
                    try await updateDownloads(configuration: configuration)
                }
            }
            
            try await group.waitForAll()
        }
    }
    static func updateDownloads(configuration: PodcastFetchConfiguration) async throws {
        let podcastID = configuration.id
        var libraryID: String? = nil
        
        logger.info("Auto downloading podcast \(podcastID)")
        
        let filter = Defaults[.episodesFilter(podcastId: podcastID)]
        let sortOrder = Defaults[.episodesSortOrder(podcastId: podcastID)]
        let ascending = Defaults[.episodesAscending(podcastId: podcastID)]
        
        // Remove existing episodes
        
        let preDownloaded = try OfflineManager.shared.episodes(podcastId: podcastID)
        let valid = Episode.filterSort(episodes: preDownloaded, filter: filter, sortOrder: sortOrder, ascending: ascending)
        let invalid = preDownloaded.filter { episode in !valid.contains { $0.id == episode.id } }
        
        for episode in invalid {
            OfflineManager.shared.remove(episodeId: episode.id)
        }
        
        // Download new episodes
        
        let episodes = try await AudiobookshelfClient.shared.episodes(podcastId: configuration.id)
        let sorted = Episode.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending)
        
        let candidates = sorted.prefix(configuration.maxEpisodes)
        var submitted = [Episode]()
        
        for candidate in candidates {
            if OfflineManager.shared.offlineStatus(parentId: candidate.id) != .downloaded {
                try await OfflineManager.shared.download(episodeId: candidate.id, podcastId: candidate.podcastId)
                submitted.append(candidate)
            }
        }
        
        // Remove additional episodes
        
        let downloaded = try OfflineManager.shared.episodes(podcastId: podcastID)
        var reversed = Episode.filterSort(episodes: downloaded, filter: filter, sortOrder: sortOrder, ascending: ascending)
        
        while reversed.count > configuration.maxEpisodes {
            OfflineManager.shared.remove(episodeId: reversed.removeLast().id)
        }
        
        // Get library ID
        
        if let episode = preDownloaded.first ?? episodes.first {
            libraryID = episode.libraryID
        }
        
        // Send notifications
        
        if !configuration.notifications {
            return
        }
        
        let content = UNMutableNotificationContent()
        
        if submitted.count == 1, let episode = submitted.first {
            content.title = String(localized: "episode.new.title \(episode.name)")
            content.subtitle = episode.podcastName
            content.body = episode.descriptionText ?? String(localized: "description.unavailable")
            
            content.threadIdentifier = episode.podcastId
            content.userInfo = [
                "libraryID": libraryID as Any,
                "episodeID": episode.id,
                "podcastID": podcastID,
            ]
        } else if !submitted.isEmpty {
            content.title = String(localized: "episodes.new.title \(submitted.count)")
            content.subtitle = episodes.first!.podcastName
            content.body = String(localized: "episodes.new.body \(submitted.count)")
            
            content.threadIdentifier = episodes.first!.podcastId
            content.userInfo = [
                "libraryID": libraryID as Any,
                "podcastID": podcastID,
            ]
        } else {
            return
        }
        
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        try? await UNUserNotificationCenter.current().add(request)
    }
}

internal extension BackgroundTaskHandler {
    static func setup() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "io.rfk.shelfplayer.autoDownloadEpisodes", using: nil, launchHandler: BackgroundTaskHandler.handle)
        submitTask()
    }
    
    static func submitTask(failed: Bool = false) {
        let request = BGAppRefreshTaskRequest(identifier: "io.rfk.shelfplayer.autoDownloadEpisodes")
        let calendar = Calendar.current
        
        let beginDate: Date
        let failCount = Defaults[.backgroundTaskFailCount]
        
        // Run at midnight if the task completed successfully, otherwise retry in one hour
        if failed && failCount <= 3 {
            beginDate = Date.now.advanced(by: 60 * 60)
            Defaults[.backgroundTaskFailCount] += 1
        } else {
            beginDate = Date.now.advanced(by: 60 * 60 * 6)
            Defaults[.backgroundTaskFailCount] = 0
        }
        
        request.earliestBeginDate = beginDate
        BGTaskScheduler.shared.cancelAllTaskRequests()
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Submitted background task, scheduled to run at \(beginDate)")
        } catch {
            logger.fault("Failed to submit background task request: \(error)")
        }
    }
}
