//
//  AudioPlayer+Update.swift
//  ShelfPlayback
//
//  Created by Rasmus Krämer on 25.02.25.
//

import Foundation
import MediaPlayer
import OSLog
import ShelfPlayerKit

extension AudioPlayer {
    func didStartPlaying(endpointID: UUID, itemID: ItemIdentifier, chapters: [Chapter], at time: TimeInterval) async {
        logger.debug("didStartPlaying itemID=\(itemID, privacy: .public) at=\(time, privacy: .public) chapters=\(chapters.count, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, policy: .default)
            try audioSession.setActive(true)
        } catch {
            logger.error("Failed to set audio session category: \(error)")
        }

        events.playbackItemChanged.send((itemID, chapters, time))

        widgetManager.update(itemID: itemID)
    }
    func playStateDidChange(endpointID: UUID, isPlaying: Bool, updateSessionActivation: Bool) async {
        logger.debug("playStateDidChange isPlaying=\(isPlaying, privacy: .public) updateSessionActivation=\(updateSessionActivation, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        if updateSessionActivation {
            do {
                try audioSession.setActive(isPlaying)
            } catch {
                logger.error("Failed to set audio session category: \(error)")
            }
        }

        events.playStateChanged.send(isPlaying)

        await widgetManager.update(isPlaying: isPlaying)
    }

    func bufferHealthDidChange(endpointID: UUID, isBuffering: Bool) async {
        logger.debug("bufferHealthDidChange isBuffering=\(isBuffering, privacy: .public)")

        guard current?.id == endpointID else {
            return
        }

        let busy = await current?.isBusy ?? false
        await widgetManager.update(isBuffering: busy)
        events.bufferHealthChanged.send(busy)
    }

    func durationsDidChange(endpointID: UUID, itemDuration: TimeInterval?, chapterDuration: TimeInterval?) async {
        logger.debug("durationsDidChange itemDuration=\(itemDuration ?? -1, privacy: .public) chapterDuration=\(chapterDuration ?? -1, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(chapterDuration: chapterDuration)
        events.durationsChanged.send((itemDuration, chapterDuration))
    }
    func currentTimesDidChange(endpointID: UUID, itemCurrentTime: TimeInterval?, chapterCurrentTime: TimeInterval?) async {
        guard current?.id == endpointID else {
            return
        }

        await widgetManager.update(chapterCurrentTime: chapterCurrentTime)
        events.currentTimesChanged.send((itemCurrentTime, chapterCurrentTime))
    }

    func chapterDidChange(endpointID: UUID, chapter: Chapter?) async {
        logger.debug("chapterDidChange hasChapter=\(chapter != nil, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(chapter: chapter)
        events.chapterChanged.send(chapter)
    }
    func chapterIndexDidChange(endpointID: UUID, chapterIndex: Int?, chapterCount: Int) async {
        logger.debug("chapterIndexDidChange index=\(chapterIndex ?? -1, privacy: .public) count=\(chapterCount, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(chapterIndex: chapterIndex, chapterCount: chapterCount)
    }

    func volumeDidChange(endpointID: UUID, volume: Percentage) async {
        logger.debug("volumeDidChange volume=\(volume, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        events.volumeChanged.send(volume)
    }

    func playbackRateDidChange(endpointID: UUID, playbackRate: Percentage) async {
        logger.debug("playbackRateDidChange rate=\(playbackRate, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(targetPlaybackRate: playbackRate)
        events.playbackRateChanged.send(playbackRate)
    }

    func routeDidChange(endpointID: UUID, route: AudioRoute) async {
        logger.debug("routeDidChange port=\(route.port.rawValue, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        events.routeChanged.send(route)
    }
    func sleepTimerDidChange(endpointID: UUID, configuration: SleepTimerConfiguration?) async {
        logger.debug("sleepTimerDidChange hasConfiguration=\(configuration != nil, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        events.sleepTimerChanged.send(configuration)
    }
    func sleepTimerDidExpire(endpointID: UUID, configuration: SleepTimerConfiguration) async {
        logger.debug("sleepTimerDidExpire")

        if current != nil && current?.id != endpointID {
            return
        }

        events.sleepTimerExpired.send(configuration)
    }

    func queueDidChange(endpointID: UUID, queue: [ItemIdentifier]) async {
        logger.debug("queueDidChange count=\(queue.count, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(queueCount: queue.count)
        events.queueChanged.send(queue)
    }
    func upNextQueueDidChange(endpointID: UUID, upNextQueue: [ItemIdentifier]) async {
        logger.debug("upNextQueueDidChange count=\(upNextQueue.count, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(upNextQueueCount: upNextQueue.count)
        events.upNextQueueChanged.send(upNextQueue)
    }
    func upNextStrategyDidChange(endpointID: UUID, strategy: ResolvedUpNextStrategy?) async {
        logger.debug("upNextStrategyDidChange hasStrategy=\(strategy != nil, privacy: .public)")

        if current != nil && current?.id != endpointID {
            return
        }

        events.upNextStrategyChanged.send(strategy)
    }

    func didStopPlaying(endpointID: UUID, itemID: ItemIdentifier) async {
        logger.debug("didStopPlaying itemID=\(itemID, privacy: .public)")

        guard current?.id == endpointID else {
            return
        }

        do {
            try audioSession.setActive(false)
        } catch {
            logger.error("Failed to deactivate audio session: \(error)")
        }

        await widgetManager.invalidate()
        events.playbackStopped.send()
    }

    func isBusyDidChange() async {
        let busy = await current?.isBusy ?? false
        logger.debug("isBusyDidChange busy=\(busy, privacy: .public)")
        await widgetManager.update(isBuffering: busy)
        events.bufferHealthChanged.send(busy)
    }
}
