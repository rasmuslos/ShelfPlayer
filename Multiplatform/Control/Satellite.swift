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
    
    private(set) var chapter: Chapter?
    
    private(set) var isPlaying: Bool
    private(set) var isBuffering: Bool
    
    private(set) var currentTime: TimeInterval
    private(set) var currentChapterTime: TimeInterval
    
    private(set) var duration: TimeInterval
    private(set) var chapterDuration: TimeInterval
    
    private(set) var volume: Percentage
    private(set) var playbackRate: Percentage
    
    private(set) var route: AudioRoute?
    
    // MARK: Playback helper
    
    private(set) var totalLoading: Int
    private(set) var busy: [ItemIdentifier: Int]
    
    // MARK: Utility
    
    private(set) var notifyError: Bool
    private(set) var notifySuccess: Bool
    
    private var stash: RFNotification.MarkerStash
    
    init() {
        isOffline = false
        
        currentItem = nil
        
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
                await endWorking(on: currentItemID, successfully: nil)
                
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
                try await AudioPlayer.shared.start(item.id)
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
                // try await AudioPlayer.shared.queue([.init(itemID: item.id, startWithoutListeningSession: <#T##Bool#>, origin: <#T##QueueItem.QueueItemOrigin#>)])
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
            
            self?.chapter = nil
            
            self?.isPlaying = false
            self?.isBuffering = true
            
            self?.currentTime = $0.1
            self?.currentChapterTime = 0
            
            self?.duration = 0
            self?.chapterDuration = 0
            
            self?.playbackRate = 0
            
            self?.route = nil
            
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
        }.store(in: &stash)
        
        RFNotification[.chapterChanged].subscribe { [weak self] chapterIndex in
            guard let chapterIndex else {
                self?.chapter = nil
                return
            }
            
            Task {
                self?.chapter = await AudioPlayer.shared.chapters[chapterIndex]
            }
        }.store(in: &stash)
        
        RFNotification[.volumeChanged].subscribe { [weak self] volume in
            self?.volume = volume
        }.store(in: &stash)
        RFNotification[.playbackRateChanged].subscribe { [weak self] playbackRate in
            self?.playbackRate = playbackRate
        }.store(in: &stash)
        
        RFNotification[.playbackStopped].subscribe { [weak self] in
            self?.currentItemID = nil
            self?.currentItem = nil
            
            self?.chapter = nil
            
            self?.isPlaying = false
            self?.isBuffering = true
            
            self?.currentTime = 0
            self?.currentChapterTime = 0
            
            self?.duration = 0
            self?.chapterDuration = 0
            
            self?.playbackRate = 0
            
            self?.route = nil
        }.store(in: &stash)
    }
}

#if DEBUG
extension Satellite {
    func debugPlayback() -> Self {
        currentItemID = .fixture
        currentItem = Audiobook.fixture
        
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
