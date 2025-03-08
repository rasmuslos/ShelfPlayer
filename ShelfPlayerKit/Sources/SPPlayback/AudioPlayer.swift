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
import Defaults
import RFNotifications
import SPFoundation
import SPPersistence

public final actor AudioPlayer: Sendable {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "AudioPlayer")
    
    var current: (any AudioEndpoint)?
    
    let audioSession = AVAudioSession.sharedInstance()
    let widgetManager = NowPlayingWidgetManager()
    
    var sleepTimerDidExpireAt: (SleepTimerConfiguration, Date)?
    
    init() {
        addRemoteCommandTargets()
        
        Task {
            await setupObservers()
        }
    }
    
    public static let shared = AudioPlayer()
}

public extension AudioPlayer {
    var currentItemID: ItemIdentifier? {
        get async {
            await current?.currentItemID
        }
    }
    var queue: [QueueItem] {
        get async {
            await current?.queue ?? []
        }
    }
    
    var chapters: [Chapter] {
        get async {
            await current?.chapters ?? []
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
    
    func start(_ itemID: ItemIdentifier, withoutListeningSession: Bool = false) async throws {
        await stop()
        
        do {
            current = try await LocalAudioEndpoint(itemID: itemID, withoutListeningSession: withoutListeningSession)
        } catch {
            await stop()
            throw error
        }
    }
    func queue(_ items: [QueueItem]) async throws {
        if let current {
            try await current.queue(items)
            return
        }
        
        guard !items.isEmpty else {
            return
        }
        
        var items = items
        let item = items.removeFirst()
        
        try await start(item.itemID, withoutListeningSession: item.startWithoutListeningSession)
        try await current!.queue(items)
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
        
        if let (configuration, date) = sleepTimerDidExpireAt {
            let distance = date.distance(to: .now)
            
            if Defaults[.extendSleepTimerOnPlay], distance <= 10 {
                await extendSleepTimer(configuration)
            }
        }
    }
    func pause() async {
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
        
        RFNotification[.skipped].send(forwards)
    }
    
    func setVolume(_ volume: Percentage) async {
        await current?.setVolume(volume)
    }
    func setPlaybackRate(_ rate: Percentage) async {
        await current?.setPlaybackRate(rate)
        
        if let itemID = await current?.currentItemID {
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
}

private extension AudioPlayer {
    func sleepTimerDidExpire(configuration: SleepTimerConfiguration) {
        sleepTimerDidExpireAt = (configuration, .now)
    }
    
    nonisolated func setupObservers() {
        Task {
            for await interval in Defaults.updates(.skipBackwardsInterval) {
                MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [NSNumber(value: interval)]
            }
        }
        Task {
            for await interval in Defaults.updates(.skipForwardsInterval) {
                MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
            }
        }
        
        RFNotification[.downloadStatusChanged].subscribe(queue: .sender) { [weak self] (itemID, status) in
            Task {
                guard await self?.current?.currentItemID == itemID else {
                    return
                }
                
                await self?.stop()
            }
        }
        
        RFNotification[.shake].subscribe(queue: .sender) { [weak self] duration in
            guard duration > 0.5 else {
                return
            }
            
            Task {
                await self?.extendSleepTimer()
            }
        }
        RFNotification[.sleepTimerExpired].subscribe(queue: .sender) { [weak self] configuration in
            Task {
                await self?.sleepTimerDidExpire(configuration: configuration)
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
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: Defaults[.skipBackwardsInterval])]
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
        
        // TODO: more
    }
}

extension RFNotification.Notification {
    static var shake: Notification<TimeInterval> {
        .init("io.rfk.shelfPlayer.shake")
    }
}
