//
//  Satellite.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.01.25.
//

import SwiftUI
import OSLog
import Defaults
import DefaultsMacros
import ShelfPlayerKit
import SPPlayback

@Observable @MainActor
final class Satellite {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Satellite")
    
    // MARK: Navigation
    
    var isOffline: Bool
    
    @ObservableDefault(.lastTabValue) @ObservationIgnored
    var lastTabValue: TabValue?
    
    // MARK: Playback
    
    private(set) var currentItemID: ItemIdentifier?
    private(set) var currentItem: PlayableItem?
    
    private(set) var queue: [ItemIdentifier]
    private(set) var upNextQueue: [ItemIdentifier]
    
    private(set) var chapter: Chapter?
    private(set) var chapters: [Chapter]
    
    private(set) var isPlaying: Bool
    private(set) var isBuffering: Bool
    
    private(set) var currentTime: TimeInterval
    private(set) var currentChapterTime: TimeInterval
    
    private(set) var duration: TimeInterval
    private(set) var chapterDuration: TimeInterval
    
    private(set) var volume: Percentage
    private(set) var playbackRate: Percentage
    
    private(set) var route: AudioRoute?
    private(set) var sleepTimer: SleepTimerConfiguration?
    
    // MARK: Playback helper
    
    private(set) var remainingSleepTime: Double?
    
    private(set) var totalLoading: Int
    private(set) var busy: [ItemIdentifier: Int]
    
    // MARK: Utility
    
    private(set) var notifyError: Bool
    private(set) var notifySuccess: Bool
    
    private var stash: RFNotification.MarkerStash
    
    init() {
        isOffline = false
        
        currentItem = nil
        
        queue = []
        upNextQueue = []
        
        chapters = []
        
        isPlaying = false
        isBuffering = true
        
        currentTime = 0
        currentChapterTime = 0
        
        duration = 0
        chapterDuration = 0
        
        volume = 0
        playbackRate = 0
        
        route = nil
        
        totalLoading = 0
        busy = [:]
        
        notifyError = false
        notifySuccess = false
        
        stash = .init()
        setupObservers()
    }
    
    enum SatelliteError: Error {
        case missingItem
    }
    
    private func startWorking(on itemID: ItemIdentifier) {
        withAnimation {
            let current = busy[itemID]
            
            if current == nil {
                busy[itemID] = 1
            } else {
                busy[itemID]! += 1
            }
        }
    }
    private func endWorking(on itemID: ItemIdentifier, successfully: Bool?) {
        withAnimation {
            guard let current = busy[itemID] else {
                logger.warning("Ending work on \(itemID) but no longer busy")
                return
            }
            
            busy[itemID] = current - 1
            
            if let successfully {
                if successfully {
                    notifySuccess.toggle()
                } else {
                    notifyError.toggle()
                }
            }
        }
    }
    
    private nonisolated func resolvePlayingItem() {
        Task {
            guard let currentItemID = await currentItemID else {
                await MainActor.withAnimation {
                    self.currentItem = nil
                }
                
                return
            }
            
            await startWorking(on: currentItemID)
            
            do {
                guard let item = try await currentItemID.resolved as? PlayableItem else {
                    throw SatelliteError.missingItem
                }
                
                await MainActor.withAnimation {
                    self.currentItem = item
                }
                await endWorking(on: currentItemID, successfully: nil)
            } catch {
                await endWorking(on: currentItemID, successfully: false)
            }
        }
    }
}

extension Satellite {
    var isNowPlayingVisible: Bool {
        currentItemID != nil
    }
    
    var played: Percentage {
        min(1, max(0, currentChapterTime / chapterDuration))
    }
    var playedTotal: Percentage {
        min(1, max(0, currentTime / duration))
    }
    
    func isLoading(observing: ItemIdentifier) -> Bool {
        totalLoading > 0 || busy[observing] ?? 0 > 0
    }
    
    nonisolated func play() {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.play()
            await endWorking(on: currentItemID, successfully: nil)
        }
    }
    nonisolated func pause() {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.pause()
            await endWorking(on: currentItemID, successfully: nil)
        }
    }
    func togglePlaying() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    nonisolated func skip(forwards: Bool) {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            
            do {
                try await AudioPlayer.shared.skip(forwards: forwards)
                await endWorking(on: currentItemID, successfully: nil)
            } catch {
                await endWorking(on: currentItemID, successfully: false)
            }
        }
    }
    nonisolated func seek(to time: TimeInterval, insideChapter: Bool, completion: (@Sendable @escaping () -> Void)) {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            
            do {
                try await AudioPlayer.shared.seek(to: time, insideChapter: insideChapter)
                await endWorking(on: currentItemID, successfully: true)
                
                completion()
            } catch {
                await endWorking(on: currentItemID, successfully: false)
            }
        }
    }
    
    nonisolated func start(_ item: PlayableItem) {
        Task {
            guard await self.currentItem != item else {
                await togglePlaying()
                return
            }
            
            await startWorking(on: item.id)
            
            do {
                try await AudioPlayer.shared.start(item.id, withoutListeningSession: isOffline)
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
    nonisolated func stop() {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.stop()
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    
    nonisolated func queue(_ item: PlayableItem) {
        Task {
            await startWorking(on: item.id)
            
            do {
                try await AudioPlayer.shared.queue([.init(itemID: item.id, startWithoutListeningSession: isOffline)])
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
    
    nonisolated func setPlaybackRate(_ rate: Percentage) {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.setPlaybackRate(rate)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func setSleepTimer(_ configuration: SleepTimerConfiguration?) {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.setSleepTimer(configuration)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func extendSleepTimer() {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.extendSleepTimer()
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    
    nonisolated func markAsFinished(_ item: PlayableItem) {
        Task {
            await startWorking(on: item.id)
            
            do {
                if await currentItemID == item.id {
                    try await AudioPlayer.shared.seek(to: duration, insideChapter: false)
                } else {
                    try await PersistenceManager.shared.progress.markAsCompleted(item.id)
                }
                
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
    nonisolated func markAsUnfinished(_ item: PlayableItem) {
        Task {
            await startWorking(on: item.id)
            
            do {
                try await PersistenceManager.shared.progress.markAsListening(item.id)
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
    nonisolated func deleteProgress(_ item: PlayableItem) {
        Task {
            await startWorking(on: item.id)
            
            do {
                try await PersistenceManager.shared.progress.delete(itemID: item.id)
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
}

private extension Satellite {
    private func setupObservers() {
        RFNotification[.changeOfflineMode].subscribe { [weak self] in
            self?.isOffline = $0
        }.store(in: &stash)
        
        RFNotification[.playbackItemChanged].subscribe { [weak self] in
            self?.currentItemID = $0.0
            self?.currentItem = nil
            
            self?.queue = []
            self?.upNextQueue = []
            
            self?.chapters = $0.1
            
            self?.isPlaying = false
            self?.isBuffering = true
            
            self?.currentTime = $0.2
            self?.currentChapterTime = 0
            
            self?.duration = 0
            self?.chapterDuration = 0
            
            self?.playbackRate = 0
            
            self?.route = nil
            self?.sleepTimer = nil
            
            self?.resolvePlayingItem()
        }.store(in: &stash)
        
        RFNotification[.playStateChanged].subscribe { [weak self] isPlaying in
            self?.notifySuccess.toggle()
            self?.isPlaying = isPlaying
        }.store(in: &stash)
        
        RFNotification[.skipped].subscribe { [weak self] _ in
            self?.notifySuccess.toggle()
        }.store(in: &stash)
        
        RFNotification[.bufferHealthChanged].subscribe { [weak self] isBuffering in
            self?.isBuffering = isBuffering
        }.store(in: &stash)
        
        RFNotification[.durationsChanged].subscribe { [weak self] durations in
            self?.duration = durations.0 ?? 0
            self?.chapterDuration = durations.1 ?? self?.duration ?? 0
        }.store(in: &stash)
        RFNotification[.currentTimesChanged].subscribe { [weak self] currentTimes in
            self?.currentTime = currentTimes.0 ?? 0
            self?.currentChapterTime = currentTimes.1 ?? self?.currentTime ?? 0
            
            if let sleepTimer = self?.sleepTimer, case .interval(let date) = sleepTimer {
                self?.remainingSleepTime = Date.now.distance(to: date)
            }
        }.store(in: &stash)
        
        RFNotification[.chapterChanged].subscribe { [weak self] chapter in
            self?.chapter = chapter
        }.store(in: &stash)
        
        RFNotification[.volumeChanged].subscribe { [weak self] volume in
            self?.volume = volume
        }.store(in: &stash)
        RFNotification[.playbackRateChanged].subscribe { [weak self] playbackRate in
            self?.playbackRate = playbackRate
        }.store(in: &stash)
        
        RFNotification[.routeChanged].subscribe { [weak self] route in
            self?.route = route
        }.store(in: &stash)
        RFNotification[.sleepTimerChanged].subscribe { [weak self] sleepTimer in
            self?.sleepTimer = sleepTimer
        }.store(in: &stash)
        
        RFNotification[.queueChanged].subscribe { [weak self] queue in
            self?.queue = queue
        }
        RFNotification[.upNextQueueChanged].subscribe { [weak self] upNextQueue in
            self?.upNextQueue = upNextQueue
        }
        
        RFNotification[.playbackStopped].subscribe { [weak self] in
            self?.currentItemID = nil
            self?.currentItem = nil
            
            self?.queue = []
            self?.upNextQueue = []
            
            self?.chapter = nil
            self?.chapters = []
            
            self?.isPlaying = false
            self?.isBuffering = true
            
            self?.currentTime = 0
            self?.currentChapterTime = 0
            
            self?.duration = 0
            self?.chapterDuration = 0
            
            self?.playbackRate = 0
            
            self?.route = nil
            self?.sleepTimer = nil
        }.store(in: &stash)
    }
}

#if DEBUG
extension Satellite {
    func debugPlayback() -> Self {
        currentItemID = .fixture
        currentItem = Audiobook.fixture
        
        chapters = [
            .init(id: 0, startOffset: 0, endOffset: 100, title: "ABC"),
            .init(id: 1, startOffset: 101, endOffset: 200, title: "DEF"),
            .init(id: 2, startOffset: 201, endOffset: 300, title: "GHI"),
            .init(id: 3, startOffset: 301, endOffset: 400, title: "JKL"),
        ]
        
        isPlaying = true
        isBuffering = false
        
        currentTime = 30
        duration = 60
        
        currentChapterTime = 5
        chapterDuration = 10
        
        return self
    }
}
#endif
