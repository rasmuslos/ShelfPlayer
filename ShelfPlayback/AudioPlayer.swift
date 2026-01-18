//
//  AudioPlayer.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation
import AVKit
import MediaPlayer
import OSLog
import RFNotifications
import ShelfPlayerKit

public final actor AudioPlayer: Sendable {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "AudioPlayer")
    
    var current: (any AudioEndpoint)?
    
    private var startTask: Task<Void, Error>? = nil
    
    let audioSession = AVAudioSession.sharedInstance()
    let widgetManager = NowPlayingWidgetManager()
    
    var didPauseAt: Date?
    var sleepTimerDidExpireAt: (SleepTimerConfiguration, Date)?
    
    init() {
        addRemoteCommandTargets()
        setupObservers()
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
            return
        }
        
        startTask = .init {
            await self.stop()
            
            do {
                current = try await LocalAudioEndpoint(item)
            } catch {
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
                    logger.error("Could not seek back 10 seconds (smart rewind): \(error)")
                }
            }
            
            self.didPauseAt = nil
        }
        
        if let (configuration, date) = sleepTimerDidExpireAt {
            let distance = date.distance(to: .now)

            if Defaults[.extendSleepTimerOnPlay], distance <= TimeInterval(Defaults[.extendSleepTimerOnPlayWindow]) {
                await extendSleepTimer(configuration)
            }
        } else if Defaults[.resetSleepTimerOnPlay], let activeTimer = await sleepTimer {
            await setSleepTimer(activeTimer.reset)
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
            amount = .init(Defaults[.skipForwardsInterval])
        } else {
            amount = -.init(Defaults[.skipBackwardsInterval])
        }
        
        try await seek(to: currentTime + amount, insideChapter: false)
        
        await RFNotification[.skipped].send(payload: forwards)
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
        if let configuration {
            await setSleepTimer(configuration.extended)
        } else if let sleepTimer = await sleepTimer {
            await setSleepTimer(sleepTimer.extended)
        } else {
            logger.warning("Can't extend sleep timer: no configuration")
        }
    }
    
    func applySmartRewind() async throws {
        guard Defaults[.enableSmartRewind] else {
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
        let playbackRates = Defaults[.playbackRates]
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
        Task {
            for await interval in Defaults.updates(.skipBackwardsInterval, initial: false) {
                MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [NSNumber(value: interval)]
            }
        }
        Task {
            for await interval in Defaults.updates(.skipForwardsInterval, initial: false) {
                MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
            }
        }
        
        RFNotification[.shake].subscribe(queue: .sender) { [weak self] duration in
            guard Defaults[.shakeExtendsSleepTimer] && duration > 0.5 else {
                return
            }
            
            Task {
                await self?.extendSleepTimer()
            }
        }
        RFNotification[.sleepTimerExpired].subscribe(queue: .sender) { [weak self] configuration in
            Task {
                await self?.sleepTimerDidExpire(configuration: configuration)
                
                do {
                    try await self?.applySmartRewind()
                } catch {
                    self?.logger.warning("Could not rewind after sleep timer expired: \(error)")
                }
            }
        }
        
        Task { [weak self] in
            for await _ in Defaults.updates(.playbackRates, initial: false) {
                self?.updateCommandCenterPlaybackRates()
            }
        }
    }
    nonisolated func addRemoteCommandTargets() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
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
            if Defaults[.lockSeekBar] {
                return .commandFailed
            }
            
            guard let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            
            let positionTime = changePlaybackPositionCommandEvent.positionTime
            
            Task {
                try await seek(to: positionTime, insideChapter: true)
            }
            
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { _ in
            Task {
                try await self.skip(forwards: false)
            }
            
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { _ in
            Task {
                try await self.skip(forwards: true)
            }
            
            return .success
        }
        
        commandCenter.seekBackwardCommand.addTarget { _ in
            Task {
                try await self.skip(forwards: false)
            }
            
            return .success
        }
        commandCenter.seekForwardCommand.addTarget { _ in
            Task {
                try await self.skip(forwards: true)
            }
            
            return .success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: Defaults[.skipBackwardsInterval])]
        commandCenter.skipBackwardCommand.addTarget { _ in
            Task {
                try await self.skip(forwards: false)
            }
            
            return .success
        }
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: Defaults[.skipForwardsInterval])]
        commandCenter.skipForwardCommand.addTarget { _ in
            Task {
                try await self.skip(forwards: true)
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
        MPRemoteCommandCenter.shared().changePlaybackRateCommand.supportedPlaybackRates = Defaults[.playbackRates].map { NSNumber(value: $0) }
    }
}

