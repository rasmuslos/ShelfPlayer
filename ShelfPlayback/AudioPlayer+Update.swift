//
//  AudioPlayer+Update.swift
//  ShelfPlayback
//
//  Created by Rasmus Krämer on 25.02.25.
//

import Foundation
import MediaPlayer
import ShelfPlayerKit

extension AudioPlayer {
    func didStartPlaying(endpointID: UUID, itemID: ItemIdentifier, chapters: [Chapter], at time: TimeInterval) async {
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
        guard current?.id == endpointID else {
            return
        }

        let busy = await current?.isBusy ?? false
        await widgetManager.update(isBuffering: busy)
        events.bufferHealthChanged.send(busy)
    }

    func durationsDidChange(endpointID: UUID, itemDuration: TimeInterval?, chapterDuration: TimeInterval?) async {
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
        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(chapter: chapter)
        events.chapterChanged.send(chapter)
    }
    func chapterIndexDidChange(endpointID: UUID, chapterIndex: Int?, chapterCount: Int) async {
        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(chapterIndex: chapterIndex, chapterCount: chapterCount)
    }

    func volumeDidChange(endpointID: UUID, volume: Percentage) async {
        if current != nil && current?.id != endpointID {
            return
        }

        events.volumeChanged.send(volume)
    }

    func playbackRateDidChange(endpointID: UUID, playbackRate: Percentage) async {
        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(targetPlaybackRate: playbackRate)
        events.playbackRateChanged.send(playbackRate)
    }

    func routeDidChange(endpointID: UUID, route: AudioRoute) async {
        if current != nil && current?.id != endpointID {
            return
        }

        events.routeChanged.send(route)
    }
    func sleepTimerDidChange(endpointID: UUID, configuration: SleepTimerConfiguration?) async {
        if current != nil && current?.id != endpointID {
            return
        }

        events.sleepTimerChanged.send(configuration)
    }
    func sleepTimerDidExpire(endpointID: UUID, configuration: SleepTimerConfiguration) async {
        if current != nil && current?.id != endpointID {
            return
        }

        events.sleepTimerExpired.send(configuration)
    }

    func queueDidChange(endpointID: UUID, queue: [ItemIdentifier]) async {
        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(queueCount: queue.count)
        events.queueChanged.send(queue)
    }
    func upNextQueueDidChange(endpointID: UUID, upNextQueue: [ItemIdentifier]) async {
        if current != nil && current?.id != endpointID {
            return
        }

        await widgetManager.update(upNextQueueCount: upNextQueue.count)
        events.upNextQueueChanged.send(upNextQueue)
    }
    func upNextStrategyDidChange(endpointID: UUID, strategy: ResolvedUpNextStrategy?) async {
        if current != nil && current?.id != endpointID {
            return
        }

        events.upNextStrategyChanged.send(strategy)
    }

    func didStopPlaying(endpointID: UUID, itemID: ItemIdentifier) async {
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
        await widgetManager.update(isBuffering: busy)
        events.bufferHealthChanged.send(busy)
    }
}
