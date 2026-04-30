//
//  AudioPlayer.swift
//  ShelfPlayback
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Combine
import Foundation
import AVKit
import MediaPlayer
import OSLog
import ShelfPlayerKit

public final actor AudioPlayer: Sendable {
    public final class EventSource: @unchecked Sendable {
        public let playbackItemChanged = PassthroughSubject<(ItemIdentifier, [Chapter], TimeInterval), Never>()
        public let playStateChanged = PassthroughSubject<Bool, Never>()
        public let skipped = PassthroughSubject<Bool, Never>()
        public let bufferHealthChanged = PassthroughSubject<Bool, Never>()
        public let durationsChanged = PassthroughSubject<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?), Never>()
        public let currentTimesChanged = PassthroughSubject<(itemDuration: TimeInterval?, chapterDuration: TimeInterval?), Never>()
        public let chapterChanged = PassthroughSubject<Chapter?, Never>()
        public let volumeChanged = PassthroughSubject<Percentage, Never>()
        public let playbackRateChanged = PassthroughSubject<Percentage, Never>()
        public let routeChanged = PassthroughSubject<AudioRoute, Never>()
        public let sleepTimerChanged = PassthroughSubject<SleepTimerConfiguration?, Never>()
        public let sleepTimerExpired = PassthroughSubject<SleepTimerConfiguration, Never>()
        public let queueChanged = PassthroughSubject<[ItemIdentifier], Never>()
        public let upNextQueueChanged = PassthroughSubject<[ItemIdentifier], Never>()
        public let upNextStrategyChanged = PassthroughSubject<ResolvedUpNextStrategy?, Never>()
        public let playbackStopped = PassthroughSubject<Void, Never>()

        init() {}
    }

    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "AudioPlayer")
    public nonisolated let events = EventSource()

    var current: (any AudioEndpoint)?

    private var startTask: Task<Void, Error>? = nil

    let audioSession = AVAudioSession.sharedInstance()
    let widgetManager = NowPlayingWidgetManager()

    var didPauseAt: Date?
    var sleepTimerDidExpireAt: (SleepTimerConfiguration, Date)?

    private var remoteSeekDirection: Bool?
    private var remoteSeekBeganAt: Date?
    private var remoteSeekAutoEndTask: Task<Void, Never>?

    nonisolated(unsafe) var observerSubscriptions = Set<AnyCancellable>()

    init() {
        setupObservers()

        Task {
            await addRemoteCommandTargets()
        }
    }

    public static let shared = AudioPlayer()
}

public extension AudioPlayer {
    var currentItemID: ItemIdentifier? {
        get async {
            await current?.currentItem.itemID
        }
    }
    var queue: [AudioPlayerItem] {
        get async {
            await current?.queue ?? []
        }
    }
    var upNextQueue: [AudioPlayerItem] {
        get async {
            await current?.upNextQueue ?? []
        }
    }

    var chapters: [Chapter] {
        get async {
            await current?.chapters ?? []
        }
    }
    var activeChapterIndex: Int? {
        get async {
            await current?.activeChapterIndex
        }
    }

    var isBusy: Bool {
        get async {
            await current?.isBusy ?? true
        }
    }
    var isPlaying: Bool {
        get async {
            await current?.isPlaying ?? false
        }
    }

    var volume: Percentage {
        get async {
            await current?.volume ?? 0
        }
    }
    var playbackRate: Percentage {
        get async {
            await current?.playbackRate ?? 0
        }
    }

    var duration: TimeInterval? {
        get async {
            await current?.duration
        }
    }
    var currentTime: TimeInterval? {
        get async {
            await current?.currentTime
        }
    }

    var chapterDuration: TimeInterval? {
        get async {
            await current?.chapterDuration
        }
    }
    var chapterCurrentTime: TimeInterval? {
        get async {
            await current?.chapterCurrentTime
        }
    }

    var route: AudioRoute? {
        get async {
            await current?.route
        }
    }
    var sleepTimer: SleepTimerConfiguration? {
        get async {
            await current?.sleepTimer
        }
    }

    var upNextStrategy: ResolvedUpNextStrategy? {
        get async {
            await current?.upNextStrategy
        }
    }
    var pendingTimeSpendListening: TimeInterval? {
        get async {
            await current?.pendingTimeSpendListening
        }
    }

    func start(_ item: AudioPlayerItem) async throws {
        guard startTask == nil else {
            logger.warning("Start already in progress; ignoring request for item \(item.itemID, privacy: .public)")
            return
        }

        startTask = .init {
            await self.stop()

            do {
                current = try await LocalAudioEndpoint(item)
            } catch {
                logger.warning("Failed to start audio player item \(item.itemID, privacy: .public): \(error, privacy: .public)")
                await self.stop()
                throw error
            }

            startTask = nil
        }

        return try await startTask!.value
    }
    @discardableResult
    func startGrouping(_ itemID: ItemIdentifier) async throws -> ItemIdentifier {
        let targetID = try await ResolveCache.nextGroupingItem(itemID).id
        try await start(.init(itemID: targetID, origin: .series(itemID)))

        return targetID
    }

    func queue(_ items: [AudioPlayerItem]) async throws {
        if let current {
            try await current.queue(items)
            return
        }

        guard !items.isEmpty else {
            return
        }

        var items = items
        let item = items.removeFirst()

        try await start(item)
        try await current!.queue(items)
    }
    @discardableResult
    func queueGrouping(_ itemID: ItemIdentifier) async throws -> ItemIdentifier {
        let targetID = try await ResolveCache.nextGroupingItem(itemID).id
        try await queue([.init(itemID: targetID, origin: .series(itemID))])

        return targetID
    }

    func stop() async {
        await current?.stop()
        current = nil
    }
    func stop(endpointID: UUID) async {
        guard current?.id == endpointID else {
            return
        }

        await stop()
    }

    func play() async {
        await current?.play()

        if let didPauseAt {
            if didPauseAt.distance(to: .now) > 30 {
                do {
                    try await applySmartRewind()
                } catch {
                    logger.error("Smart rewind failed (delta >= 30s): \(error, privacy: .public)")
                }
            }

            self.didPauseAt = nil
        }

        if let (configuration, date) = sleepTimerDidExpireAt {
            let distance = date.distance(to: .now)

            if AppSettings.shared.extendSleepTimerOnPlay, distance <= 10 {
                await extendSleepTimer(configuration)
            }
        }
    }
    func pause() async {
        didPauseAt = .now
        await current?.pause()
    }

    func seek(to time: TimeInterval, insideChapter: Bool) async throws {
        if let current {
            try await current.seek(to: time, insideChapter: insideChapter)
        }
    }
    func skip(forwards: Bool) async throws {
        guard let currentTime = await currentTime else {
            throw AudioPlayerError.invalidTime
        }

        let amount: TimeInterval

        if forwards {
            amount = .init(AppSettings.shared.skipForwardsInterval)
        } else {
            amount = -.init(AppSettings.shared.skipBackwardsInterval)
        }

        try await seek(to: currentTime + amount, insideChapter: false)

        events.skipped.send(forwards)
    }

    func move(queueIndex: IndexSet, to: Int) async {
        await current?.move(queueIndex: queueIndex, to: to)
    }

    func setVolume(_ volume: Percentage) async {
        await current?.setVolume(volume)
    }
    func setPlaybackRate(_ rate: Percentage) async {
        await current?.setPlaybackRate(rate)

        if let itemID = await currentItemID {
            Task {
                do {
                    try await PersistenceManager.shared.item.setPlaybackRate(rate, for: itemID)
                } catch {
                    logger.error("Failed to store playback rate: \(error)")
                }
            }
        }
    }

    func handleRemoteSeek(forwards: Bool, type: MPSeekCommandEventType?) async {
        guard current != nil else {
            return
        }

        if type == .endSeeking {
            let beganAt = remoteSeekBeganAt
            await stopRemoteSeek()

            // Some senders (e.g. CarPlay rocker buttons) translate a short tap into
            // begin+end fast-forward within milliseconds. Treat that as a skip command.
            if let beganAt, Date().timeIntervalSince(beganAt) < 0.35 {
                do {
                    try await skip(forwards: forwards)
                } catch {
                    logger.error("MP-Command: skip-on-tap failed: \(error)")
                }
            }
            return
        }

        if let direction = remoteSeekDirection, direction != forwards {
            await current?.endSeeking()
            remoteSeekDirection = nil
            remoteSeekBeganAt = nil
        }

        if remoteSeekDirection == nil {
            remoteSeekDirection = forwards
            remoteSeekBeganAt = Date()
            await current?.beginSeeking(forwards)
        }

        remoteSeekAutoEndTask?.cancel()
        let timeout = max(0.05, AppSettings.shared.remoteSeekAutoEndInterval)
        remoteSeekAutoEndTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeout))
            guard !Task.isCancelled else {
                return
            }
            await self?.stopRemoteSeek()
        }
    }

    private func stopRemoteSeek() async {
        remoteSeekAutoEndTask?.cancel()
        remoteSeekAutoEndTask = nil

        guard remoteSeekDirection != nil else {
            return
        }

        remoteSeekDirection = nil
        remoteSeekBeganAt = nil
        await current?.endSeeking()
    }

    func setSleepTimer(_ configuration: SleepTimerConfiguration?) async {
        await current?.setSleepTimer(configuration)
    }

    func skip(queueIndex index: Int) async {
        await current?.skip(queueIndex: index)
    }
    func skip(upNextQueueIndex index: Int) async {
        await current?.skip(upNextQueueIndex: index)
    }

    func remove(queueIndex index: Int) async {
        await current?.remove(queueIndex: index)
    }
    func remove(upNextQueueIndex index: Int) async {
        await current?.remove(upNextQueueIndex: index)
    }

    func clearQueue() async {
        await current?.clearQueue()
    }
    func clearUpNextQueue() async {
        await current?.clearUpNextQueue()
    }

    func extendSleepTimer(_ configuration: SleepTimerConfiguration? = nil) async {
        let settings = AppSettings.shared
        if let configuration {
            await setSleepTimer(configuration.extended(byPreviousSetting: settings.extendSleepTimerByPreviousSetting, extendInterval: settings.sleepTimerExtendInterval, extendChapterAmount: settings.sleepTimerExtendChapterAmount))
        } else if let sleepTimer = await sleepTimer {
            await setSleepTimer(sleepTimer.extended(byPreviousSetting: settings.extendSleepTimerByPreviousSetting, extendInterval: settings.sleepTimerExtendInterval, extendChapterAmount: settings.sleepTimerExtendChapterAmount))
        } else {
            logger.warning("Can't extend sleep timer: no configuration")
        }
    }

    func applySmartRewind() async throws {
        guard AppSettings.shared.enableSmartRewind else {
            return
        }

        guard let currentTime = await currentTime else {
            return
        }

        let target = currentTime - 10

        if let activeChapterIndex = await activeChapterIndex {
            let startOffset = await chapters[activeChapterIndex].startOffset
            try await seek(to: max(startOffset, target), insideChapter: false)
        } else {
            try await seek(to: target, insideChapter: false)
        }
    }

    func createQuickBookmark() async throws {
        guard let currentItemID = await currentItemID, let currentTime = await currentTime else {
            throw AudioPlayerError.invalidTime
        }

        let note = Date.now.formatted(date: .abbreviated, time: .shortened)

        try await PersistenceManager.shared.bookmark.create(at: UInt64(currentTime), note: note, for: currentItemID)
    }

    func cyclePlaybackSpeed() async {
        let playbackRates = AppSettings.shared.playbackRates
        let playbackRate = await playbackRate

        guard let index = playbackRates.firstIndex(where: {
            $0 + 0.001 > playbackRate
            && $0 - 0.001 < playbackRate
        }) else {
            if let rate = playbackRates.first {
                await setPlaybackRate(rate)
            }

            return
        }

        if index + 1 < playbackRates.count {
            await setPlaybackRate(playbackRates[index + 1])
        } else if let rate = playbackRates.first {
            await setPlaybackRate(rate)
        }
    }
    func advance() async {
        if await !queue.isEmpty {
            await skip(queueIndex: 0)
        } else if await !upNextQueue.isEmpty {
            await skip(upNextQueueIndex: 0)
        }
    }
}

private extension AudioPlayer {
    func sleepTimerDidExpire(configuration: SleepTimerConfiguration) {
        sleepTimerDidExpireAt = (configuration, .now)
    }

    nonisolated func setupObservers() {
        let settings = AppSettings.shared

        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [NSNumber(value: settings.skipBackwardsInterval)]
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [NSNumber(value: settings.skipForwardsInterval)]

        AppEventSource.shared.shake
            .sink { [weak self] duration in
                guard settings.shakeExtendsSleepTimer && duration > 0.5 else {
                    return
                }

                Task {
                    await self?.extendSleepTimer()
                }
            }
            .store(in: &observerSubscriptions)
        events.sleepTimerExpired
            .sink { [weak self] configuration in
                Task {
                    await self?.sleepTimerDidExpire(configuration: configuration)

                    do {
                        try await self?.applySmartRewind()
                    } catch {
                        self?.logger.warning("Could not rewind after sleep timer expired: \(error)")
                    }
                }
            }
            .store(in: &observerSubscriptions)

        updateCommandCenterPlaybackRates()
    }
    @MainActor
    func addRemoteCommandTargets() {
        let commandCenter = MPRemoteCommandCenter.shared()
        let settings = AppSettings.shared

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            Task {
                await self.play()
            }

            return .success
        }
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            Task {
                await self.pause()
            }

            return .success
        }
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            Task {
                if await self.isPlaying {
                    await self.pause()
                } else {
                    await self.play()
                }
            }

            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            self.logger.info("MP-Command: changePlaybackPosition triggered")

            if settings.lockSeekBar {
                self.logger.error("MP-Command: changePlaybackPosition failed: seek bar is locked")

                return .commandFailed
            }

            guard let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent else {
                self.logger.error("MP-Command: changePlaybackPosition failed: invalid event type")

                return .commandFailed
            }

            let positionTime = changePlaybackPositionCommandEvent.positionTime

            Task {
                do {
                    try await seek(to: positionTime, insideChapter: true)
                } catch {
                    self.logger.error("MP-Command: changePlaybackPosition failed: \(error)")
                }
            }

            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.addTarget { _ in
            Task {
                do {
                    try await self.skip(forwards: false)
                } catch {
                    self.logger.error("MP-Command: previousTrack failed: \(error)")
                }
            }

            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.addTarget { _ in
            Task {
                do {
                    try await self.skip(forwards: true)
                } catch {
                    self.logger.error("MP-Command: nextTrack failed: \(error)")
                }
            }

            return .success
        }

        commandCenter.seekBackwardCommand.isEnabled = true
        commandCenter.seekBackwardCommand.addTarget { event in
            let type = (event as? MPSeekCommandEvent)?.type
            self.logger.info("MP-Command: seekBackward triggered (type=\(String(describing: type?.rawValue)))")

            Task {
                await self.handleRemoteSeek(forwards: false, type: type)
            }

            return .success
        }
        commandCenter.seekForwardCommand.isEnabled = true
        commandCenter.seekForwardCommand.addTarget { event in
            let type = (event as? MPSeekCommandEvent)?.type
            self.logger.info("MP-Command: seekForward triggered (type=\(String(describing: type?.rawValue)))")

            Task {
                await self.handleRemoteSeek(forwards: true, type: type)
            }

            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: settings.skipBackwardsInterval)]
        commandCenter.skipBackwardCommand.addTarget { _ in
            Task {
                self.logger.info("MP-Command: skipBackward triggered")

                do {
                    try await self.skip(forwards: false)
                } catch {
                    self.logger.error("MP-Command: skipBackward failed: \(error)")
                }
            }

            return .success
        }
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: settings.skipForwardsInterval)]
        commandCenter.skipForwardCommand.addTarget { _ in
            Task {
                self.logger.info("MP-Command: skipForward triggered")

                do {
                    try await self.skip(forwards: true)
                } catch {
                    self.logger.error("MP-Command: skipForward failed: \(error)")
                }
            }

            return .success
        }

        commandCenter.bookmarkCommand.isEnabled = true
        commandCenter.bookmarkCommand.addTarget { _ in
            Task {
                do {
                    try await self.createQuickBookmark()
                } catch {
                    self.logger.error("Failed to create quick bookmark: \(error)")
                }
            }

            return .success
        }

        updateCommandCenterPlaybackRates()
        commandCenter.changePlaybackRateCommand.isEnabled = true
        commandCenter.changePlaybackRateCommand.addTarget {
            guard let event = $0 as? MPChangePlaybackRateCommandEvent else {
                return .commandFailed
            }

            let value = Percentage(event.playbackRate)

            Task {
                await self.setPlaybackRate(value)
            }

            return .success
        }

        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { _ in
            Task {
                await self.stop()
            }

            return .success
        }
    }

    nonisolated func updateCommandCenterPlaybackRates() {
        MPRemoteCommandCenter.shared().changePlaybackRateCommand.supportedPlaybackRates = AppSettings.shared.playbackRates.map { NSNumber(value: $0) }
    }
}
