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
    
    var currentSheet: Sheet?
    
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
    
    private(set) var bookmarks: [Bookmark]
    
    // MARK: Playback helper
    
    private(set) var remainingSleepTime: Double?
    
    private(set) var totalLoading: Int
    private(set) var busy: [ItemIdentifier: Int]
    
    var resumePlaybackItemID: ItemIdentifier?
    
    // MARK: Utility
    
    private(set) var notifyError: Bool
    private(set) var notifySuccess: Bool
    
    private var stash: RFNotification.MarkerStash
    
    init() {
        isOffline = Defaults[.startInOfflineMode]
        
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
        
        bookmarks = []
        
        totalLoading = 0
        busy = [:]
        
        notifyError = false
        notifySuccess = false
        
        stash = .init()
        setupObservers()
        
        checkForResumablePlayback()
    }
    
    enum Sheet: Identifiable {
        case preferences
        
        case description(_ item: Item)
        case podcastConfiguration(_ podcastID: ItemIdentifier)
        
        var id: String {
            switch self {
            case .preferences:
                "preferences"
            case .description(let item):
                "descritpion_\(item.id)"
            case .podcastConfiguration(let itemID):
                "podcastConfiguration_\(itemID)"
            }
        }
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
}

extension Satellite {
    var isNowPlayingVisible: Bool {
        currentItemID != nil
    }
    var isSheetPresented: Bool {
        currentSheet != nil
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
    
    func present(_ sheet: Sheet) {
        currentSheet = sheet
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
    
    nonisolated func start(_ itemID: ItemIdentifier) {
        Task {
            guard await self.currentItemID != itemID else {
                await togglePlaying()
                return
            }
            
            await startWorking(on: itemID)
            
            do {
                try await AudioPlayer.shared.start(itemID, withoutListeningSession: isOffline)
                await endWorking(on: itemID, successfully: true)
            } catch {
                await endWorking(on: itemID, successfully: false)
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
    
    nonisolated func queue(_ itemID: ItemIdentifier) {
        Task {
            await startWorking(on: itemID)
            
            do {
                try await AudioPlayer.shared.queue([.init(itemID: itemID, startWithoutListeningSession: isOffline)])
                await endWorking(on: itemID, successfully: true)
            } catch {
                await endWorking(on: itemID, successfully: false)
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
    
    nonisolated func skip(queueIndex index: Int) {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.skip(queueIndex: index)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func skip(upNextQueueIndex index: Int) {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.skip(upNextQueueIndex: index)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    
    nonisolated func remove(queueIndex index: Int) {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.remove(queueIndex: index)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func remove(upNextQueueIndex index: Int) {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.remove(upNextQueueIndex: index)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    
    nonisolated func clearQueue() {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.clearQueue()
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func clearUpNextQueue() {
        Task {
            guard let currentItemID = await currentItemID else {
                return
            }
            
            await startWorking(on: currentItemID)
            await AudioPlayer.shared.clearUpNextQueue()
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    
    nonisolated func markAsFinished(_ itemID: ItemIdentifier) {
        Task {
            await startWorking(on: itemID)
            
            do {
                if await currentItemID == itemID {
                    try await AudioPlayer.shared.seek(to: duration, insideChapter: false)
                } else {
                    try await PersistenceManager.shared.progress.markAsCompleted(itemID)
                }
                
                while let index = await queue.firstIndex(of: itemID) {
                    remove(queueIndex: index)
                }
                
                await endWorking(on: itemID, successfully: true)
            } catch {
                await endWorking(on: itemID, successfully: false)
            }
        }
    }
    nonisolated func markAsUnfinished(_ itemID: ItemIdentifier) {
        Task {
            await startWorking(on: itemID)
            
            do {
                try await PersistenceManager.shared.progress.markAsListening(itemID)
                await endWorking(on: itemID, successfully: true)
            } catch {
                await endWorking(on: itemID, successfully: false)
            }
        }
    }
    nonisolated func deleteProgress(_ itemID: ItemIdentifier) {
        Task {
            await startWorking(on: itemID)
            
            do {
                try await PersistenceManager.shared.progress.delete(itemID: itemID)
                await endWorking(on: itemID, successfully: true)
            } catch {
                await endWorking(on: itemID, successfully: false)
            }
        }
    }
    
    nonisolated func deleteBookmark(at time: UInt64, from itemID: ItemIdentifier) {
        Task {
            await startWorking(on: itemID)
            
            do {
                try await PersistenceManager.shared.bookmark.delete(at: time, from: itemID)
                
                if await currentItemID == itemID {
                    await MainActor.withAnimation {
                        bookmarks.removeAll {
                            $0.time == time
                        }
                    }
                }
                
                await endWorking(on: itemID, successfully: true)
            } catch {
                await endWorking(on: itemID, successfully: false)
            }
        }
    }
    
    nonisolated func resumePlayback() {
        Task {
            guard let resumePlaybackItemID = await resumePlaybackItemID else {
                return
            }
            
            await MainActor.run {
                self.resumePlaybackItemID = nil
            }
            
            start(resumePlaybackItemID)
        }
    }
}

private extension Satellite {
    nonisolated func resolvePlayingItem() {
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
    nonisolated func loadBookmarks(itemID: ItemIdentifier) {
        Task {
            do {
                guard itemID.type == .audiobook else {
                    throw CancellationError()
                }
                
                let bookmarks = try await PersistenceManager.shared.bookmark[itemID]
                
                await MainActor.withAnimation {
                    self.bookmarks = bookmarks
                }
            } catch {
                await MainActor.withAnimation {
                    self.bookmarks = []
                }
            }
        }
    }
    
    func checkForResumablePlayback() {
        guard let playbackResumeInfo = Defaults[.playbackResumeInfo] else {
            return
        }
        
        Defaults[.playbackResumeInfo] = nil
        
        // 12 Hours
        let timeout: Double = 60 * 60 * 12
        
        guard playbackResumeInfo.started.distance(to: .now) < timeout else {
            return
        }
        
        resumePlaybackItemID = playbackResumeInfo.itemID
    }
    
    func setupObservers() {
        RFNotification[.changeOfflineMode].subscribe { [weak self] in
            self?.isOffline = $0
        }.store(in: &stash)
        
        RFNotification[.playbackItemChanged].subscribe { [weak self] in
            self?.currentItemID = $0.0
            self?.currentItem = nil
            
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
            self?.loadBookmarks(itemID: $0.0)
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
            
            self?.bookmarks = []
        }.store(in: &stash)
        
        RFNotification[.bookmarksChanged].subscribe { [weak self] itemID in
            guard self?.currentItemID == itemID else {
                return
            }
            
            self?.loadBookmarks(itemID: itemID)
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
