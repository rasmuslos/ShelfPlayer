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
import SPBase
import SPOffline
import SPOfflineExtended
import UserNotifications

final class BackgroundTaskHandler {
    static let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "Background Tasks")
}

extension BackgroundTaskHandler {
    static func handle(task: BGTask) {
        let backgroundTask = Task.detached {
            do {
                try await Self.runAutoDownload()
                
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
 
extension BackgroundTaskHandler {
    static func runAutoDownload() async throws {
        let configurations = try await OfflineManager.shared.getConfigurations(active: true)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for configuration in configurations {
                group.addTask { try await runAutoDownload(configuration: configuration) }
            }
            
            try await group.waitForAll()
        }
    }
    static func runAutoDownload(configuration: PodcastFetchConfiguration) async throws {
        let podcastId = configuration.id
        logger.info("Auto downloading podcast \(podcastId)")
        
        let filter = Defaults[.episodesFilter(podcastId: podcastId)]
        let sortOrder = Defaults[.episodesSort(podcastId: podcastId)]
        let ascending = Defaults[.episodesAscending(podcastId: podcastId)]
        
        // Remove existing episodes
        
        let preDownloaded = try await OfflineManager.shared.getEpisodes(podcastId: podcastId)
        let valid = await EpisodeSortFilter.filterSort(episodes: preDownloaded, filter: filter, sortOrder: sortOrder, ascending: ascending)
        let invalid = preDownloaded.filter { episode in !valid.contains { $0.id == episode.id } }
        
        for episode in invalid {
            await OfflineManager.shared.delete(episodeId: episode.id)
        }
        
        // Download new episodes
        
        let episodes = try await AudiobookshelfClient.shared.getEpisodes(podcastId: configuration.id)
        let sorted = await EpisodeSortFilter.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending)
        
        let candidates = sorted.prefix(configuration.maxEpisodes)
        var submitted = [Episode]()
        
        for candidate in candidates {
            if !(await OfflineManager.shared.isDownloadFinished(episodeId: candidate.id)) {
                try await OfflineManager.shared.download(episodeId: candidate.id, podcastId: candidate.podcastId)
                submitted.append(candidate)
            }
        }
        
        // Remove additional episodes
        
        let downloaded = try await OfflineManager.shared.getEpisodes(podcastId: podcastId)
        var reversed = await EpisodeSortFilter.filterSort(episodes: downloaded, filter: filter, sortOrder: sortOrder, ascending: ascending)
        
        while reversed.count > configuration.maxEpisodes {
            await OfflineManager.shared.delete(episodeId: reversed.removeLast().id)
        }
        
        // Send notifications
        
        if !configuration.notifications {
            return
        }
        
        let content = UNMutableNotificationContent()
        var sendNotification = true
        
        if submitted.count == 1, let episode = submitted.first {
            content.title = String(localized: "episode.new.title \(episode.name)")
            content.subtitle = episode.podcastName
            content.body = episode.descriptionText ?? String(localized: "description.unavailable")
            
            content.threadIdentifier = episode.podcastId
            content.userInfo = [
                "episodeId": episode.id,
                "podcastId": podcastId,
            ]
        } else if !submitted.isEmpty {
            content.title = String(localized: "episodes.new.title \(submitted.count)")
            content.subtitle = episodes.first!.podcastName
            content.body = String(localized: "episodes.new.body \(submitted.count)")
            
            content.threadIdentifier = episodes.first!.podcastId
            content.userInfo = [
                "podcastId": podcastId,
            ]
        } else {
            sendNotification = false
        }
        
        content.sound = UNNotificationSound.default
        
        if sendNotification {
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}

extension BackgroundTaskHandler {
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
            beginDate = calendar.date(byAdding: .hour, value: 1, to: Date())!
            Defaults[.backgroundTaskFailCount] += 1
        } else {
            beginDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
            Defaults[.backgroundTaskFailCount] = 0
        }
        
        request.earliestBeginDate = beginDate
        BGTaskScheduler.shared.cancelAllTaskRequests()
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Submitted background task, scheduled to run at \(beginDate)")
        } catch {
            logger.fault("Failed to submit background task request")
            print(error)
        }
    }
}

extension Defaults.Keys {
    static let backgroundTaskFailCount = Key<Int>("backgroundTaskFailCount", default: 0)
}
