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

class BackgroundTaskHandler {
    static let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "Background Tasks")
}

extension BackgroundTaskHandler {
    static func handle(task: BGTask) {
        let backgroundTask = Task.detached {
            guard let configurations = try? await OfflineManager.shared.getConfigurations(active: true) else {
                logger.fault("Failed to fetch configurations")
                return
            }
            
            for configuration in configurations {
                let podcastId = configuration.id
                logger.info("Auto downloading podcast \(podcastId)")
                
                let filter = Defaults[.episodesFilter(podcastId: podcastId)]
                let sortOrder = Defaults[.episodesSort(podcastId: podcastId)]
                let ascending = Defaults[.episodesAscending(podcastId: podcastId)]
                
                let episodes = try await AudiobookshelfClient.shared.getEpisodes(podcastId: configuration.id)
                let sorted = await EpisodeSortFilter.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending)
                
                let candidates = sorted.prefix(configuration.maxEpisodes)
                var submitted = [Episode]()
                
                for candidate in candidates {
                    if !(await OfflineManager.shared.isDownloadFinished(episodeId: candidate.id)) {
                        try? await OfflineManager.shared.download(episodeId: candidate.id, podcastId: candidate.podcastId)
                        submitted.append(candidate)
                    }
                }
                
                let downloaded = try await OfflineManager.shared.getEpisodes(podcastId: podcastId)
                var reversed = await EpisodeSortFilter.filterSort(episodes: downloaded, filter: filter, sortOrder: sortOrder, ascending: ascending)
                
                while reversed.count > configuration.maxEpisodes {
                    await OfflineManager.shared.delete(episodeId: reversed.removeLast().id)
                }
                
                if !configuration.notifications {
                    continue
                }
                
                let content = UNMutableNotificationContent()
                var sendNotification = true
                
                if submitted.count == 1, let episode = submitted.first {
                    content.title = String(localized: "episode.new.title \(episode.name)")
                    content.subtitle = episode.podcastName
                    content.body = episode.descriptionText ?? String(localized: "description.unavailable")
                    
                    content.threadIdentifier = episode.podcastId
                } else if !submitted.isEmpty {
                    content.body = String(localized: "episodes.new.title \(submitted.count)")
                    content.subtitle = episodes.first!.podcastName
                    content.body = String(localized: "episodes.new.body \(submitted.count)")
                    
                    content.threadIdentifier = episodes.first!.podcastId
                } else {
                    sendNotification = false
                }
                
                content.sound = UNNotificationSound.default

                if sendNotification {
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
                    try! await UNUserNotificationCenter.current().add(request)
                }
            }
            
            submitTask()
            task.setTaskCompleted(success: true)
        }
        
        task.expirationHandler = {
            backgroundTask.cancel()
        }
    }
}

extension BackgroundTaskHandler {
    static func setup() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "io.rfk.shelfplayer.autoDownloadEpisodes", using: nil, launchHandler: BackgroundTaskHandler.handle)
        submitTask()
    }
    
    static func submitTask() {
        let request = BGAppRefreshTaskRequest(identifier: "io.rfk.shelfplayer.autoDownloadEpisodes")
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(bySetting: .day, value: 1, of: Date())!)
        
        request.earliestBeginDate = midnight
        BGTaskScheduler.shared.cancelAllTaskRequests()
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Submitted background task, scheduled to run at \(midnight)")
        } catch {
            logger.fault("Failed to submit background task request")
            print(error)
        }
    }
}
