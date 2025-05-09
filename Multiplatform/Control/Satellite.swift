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
    
    private(set) var sheetStack: [Sheet]
    var warningAlert: WarningAlert?

    // MARK: Playback
    
    private(set) var nowPlayingItemID: ItemIdentifier?
    private(set) var nowPlayingItem: PlayableItem?
    
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
    
    private(set) var skipCache: TimeInterval?
    
    @ObservationIgnored
    private(set) nonisolated(unsafe) var skipTask: Task<Void, Never>?
    
    var resumePlaybackItemID: ItemIdentifier?
    
    // MARK: Utility
    
    private(set) var notifyError: Bool
    private(set) var notifySuccess: Bool
    
    private var stash: RFNotification.MarkerStash
    
    // MARK: Init
    
    init() {
        isOffline = Defaults[.startInOfflineMode]
        
        sheetStack = []
        
        nowPlayingItem = nil
        
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
    
    // MARK: General Purpose
    
    enum SatelliteError: Error {
        case missingItem
    }

    public func isLoading(observing: ItemIdentifier) -> Bool {
        totalLoading > 0 || busy[observing] ?? 0 > 0
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
                logger.warning("Ending work on \(itemID, privacy: .public) but no longer busy")
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

// MARK: Sheet & Alert

extension Satellite {
    enum Sheet: Identifiable, Equatable {
        case listenNow
        
        case preferences
        
        case description(_ item: Item)
        case podcastConfiguration(_ podcastID: ItemIdentifier)
        
        var id: String {
            switch self {
            case .listenNow:
                "listenNow"
            case .preferences:
                "preferences"
            case .description(let item):
                "description_\(item.id)"
            case .podcastConfiguration(let itemID):
                "podcastConfiguration_\(itemID)"
            }
        }
        
        var dismissBehavior: DismissBehavior {
            switch self {
            case .listenNow, .preferences, .description:
                    .allow
            case .podcastConfiguration:
                    .warn(message: String(localized: "toDo"))
            }
        }
        
        enum DismissBehavior {
            case allow
            case warn(message: String)
            case prevent

            var preventInteraction: Bool {
                switch self {
                case .allow, .warn:
                    false
                case .prevent:
                    true
                }
            }
        }
    }
    enum WarningAlert: LocalizedError {
        case sheetDismissalPrevention(sheet: Sheet)

        var errorDescription: String? {
            switch self {
            case .sheetDismissalPrevention(let sheet):
                switch sheet.dismissBehavior {
                case .allow, .prevent:
                    nil
                case .warn(let message):
                    message
                }
            }
        }
    }

    var isSheetPresented: Bool {
        !sheetStack.isEmpty
    }
    var presentedSheet: Binding<Sheet?> {
        .init {
            self.sheetStack.first
        } set: {
            if let sheet = $0, self.sheetStack.first != sheet {
                self.present(sheet)
            } else if $0 == nil {
                self.attemptSheetDismissal()
            }
        }
    }
    var isWarningAlertPresented: Binding<Bool> {
        .init {
            self.warningAlert != nil
        } set: { _ in }
    }
    
    func present(_ sheet: Sheet) {
        sheetStack.append(sheet)
    }
    
    func attemptSheetDismissal() {
        guard let sheet = sheetStack.first else {
            return
        }
        
        let dismissalBehavior = sheet.dismissBehavior
        
        switch dismissalBehavior {
        case .allow:
            dismissSheet()
        case .warn:
            warningAlert = .sheetDismissalPrevention(sheet: sheet)
        case .prevent:
            break
        }
    }
    func dismissSheet() {
        guard let sheet = sheetStack.first else {
            return
        }
        
        switch sheet.dismissBehavior {
        case .allow:
            break
        case .warn:
            guard case .sheetDismissalPrevention(let warningSheet) = self.warningAlert, warningSheet == sheet else {
                return
            }
        case .prevent:
            return
        }
        
        if case .prevent = sheet.dismissBehavior {
            return
        }
        
        sheetStack.removeFirst()
    }

    func cancelWarningAlert() {
        warningAlert = nil
    }
    func confirmWarningAlert() {
        guard let warningAlert = warningAlert else {
            return
        }
        
        switch warningAlert {
        case .sheetDismissalPrevention:
            dismissSheet()
        }
        
        self.warningAlert = nil
    }
}

// MARK: Miscellaneous

extension Satellite {
    nonisolated func deleteBookmark(at time: UInt64, from itemID: ItemIdentifier) {
        Task {
            await startWorking(on: itemID)

            do {
                try await PersistenceManager.shared.bookmark.delete(at: time, from: itemID)

                if await nowPlayingItemID == itemID {
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
}

// MARK: Now Playing

extension Satellite {
    var isNowPlayingVisible: Bool {
        nowPlayingItemID != nil
    }

    var played: Percentage {
        min(1, max(0, currentChapterTime / chapterDuration))
    }
    var playedTotal: Percentage {
        min(1, max(0, currentTime / duration))
    }


    nonisolated func play() {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.play()
            await endWorking(on: currentItemID, successfully: nil)
        }
    }
    nonisolated func pause() {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
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
            guard let currentItemID = await nowPlayingItemID else {
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
            guard let currentItemID = await nowPlayingItemID else {
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

    func skipPressed(forwards: Bool) {
        let isInitial: Bool
        let adjustment = Double(forwards ? Defaults[.skipForwardsInterval] : -Defaults[.skipBackwardsInterval])

        if let skipCache {
            isInitial = false
            self.skipCache = skipCache + adjustment
        } else {
            isInitial = true
            self.skipCache = adjustment
        }

        RFNotification[.skipped].send(payload: forwards)

        skipTask?.cancel()
        skipTask = Task {
            try? await Task.sleep(for: .seconds(isInitial ? 0.2 : 0.6))

            guard !Task.isCancelled else {
                return
            }

            if let skipCache {
                self.skipCache = nil
                seek(to: currentTime + skipCache, insideChapter: false) {}
            }
        }
    }

    nonisolated func start(_ itemID: ItemIdentifier) {
        Task {
            guard await self.nowPlayingItemID != itemID else {
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
            guard let currentItemID = await nowPlayingItemID else {
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
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.setPlaybackRate(rate)
            await endWorking(on: currentItemID, successfully: true)
        }
    }

    nonisolated func setSleepTimer(_ configuration: SleepTimerConfiguration?) {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.setSleepTimer(configuration)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func extendSleepTimer() {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.extendSleepTimer()
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func setSleepTimerToChapter(_ chapter: Chapter) {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            let chapters = await AudioPlayer.shared.chapters

            guard let index = chapters.firstIndex(of: chapter),
                  let currentChapterIndex = await AudioPlayer.shared.activeChapterIndex,
                  index >= currentChapterIndex else {
                await endWorking(on: currentItemID, successfully: false)
                return
            }

            let amount = index - currentChapterIndex + 1

            await AudioPlayer.shared.setSleepTimer(.chapters(amount))
            await endWorking(on: currentItemID, successfully: true)
        }
    }

    nonisolated func skip(queueIndex index: Int) {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.skip(queueIndex: index)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func skip(upNextQueueIndex index: Int) {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.skip(upNextQueueIndex: index)
            await endWorking(on: currentItemID, successfully: true)
        }
    }

    nonisolated func remove(queueIndex index: Int) {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.remove(queueIndex: index)
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func remove(upNextQueueIndex index: Int) {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.remove(upNextQueueIndex: index)
            await endWorking(on: currentItemID, successfully: true)
        }
    }

    nonisolated func clearQueue() {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.clearQueue()
            await endWorking(on: currentItemID, successfully: true)
        }
    }
    nonisolated func clearUpNextQueue() {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.clearUpNextQueue()
            await endWorking(on: currentItemID, successfully: true)
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

// MARK: Progress

extension Satellite {
    nonisolated func markAsFinished(_ itemID: ItemIdentifier) {
        Task {
            await startWorking(on: itemID)
            
            do {
                if await nowPlayingItemID == itemID {
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
}

// MARK: Download

extension Satellite {
    nonisolated func download(itemID: ItemIdentifier) throws {
        Task {
            let status = await PersistenceManager.shared.download.status(of: itemID)

            guard status == .none else {
                return
            }
            
            if await nowPlayingItemID == itemID {
                
            }

            await startWorking(on: itemID)

            do {
                try await PersistenceManager.shared.download.download(itemID)
                await endWorking(on: itemID, successfully: true)
            } catch {
                logger.error("Failed to download item \(itemID, privacy: .public): \(error)")
                await endWorking(on: itemID, successfully: false)
            }
        }
    }
}

// MARK: Private

private extension Satellite {
    nonisolated func resolvePlayingItem() {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                await MainActor.withAnimation {
                    self.nowPlayingItem = nil
                }
                
                return
            }
            
            await startWorking(on: currentItemID)
            
            do {
                guard let item = try await currentItemID.resolved as? PlayableItem else {
                    throw SatelliteError.missingItem
                }
                
                await MainActor.withAnimation {
                    self.nowPlayingItem = item
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

    // MARK: Observers

    func setupObservers() {
        RFNotification[.changeOfflineMode].subscribe { [weak self] in
            if $0 {
                let appearance = UINavigationBarAppearance()
                
                appearance.configureWithTransparentBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().compactAppearance = appearance
            }
            
            self?.isOffline = $0
        }.store(in: &stash)
        
        RFNotification[.navigateNotification].subscribe { [weak self] _ in
            self?.attemptSheetDismissal()
        }.store(in: &stash)
        
        RFNotification[.playbackItemChanged].subscribe { [weak self] in
            self?.nowPlayingItemID = $0.0
            self?.nowPlayingItem = nil
            
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
            self?.nowPlayingItemID = nil
            self?.nowPlayingItem = nil
            
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
            guard self?.nowPlayingItemID == itemID else {
                return
            }
            
            self?.loadBookmarks(itemID: itemID)
        }.store(in: &stash)
    }
}

// MARK: Debug fixture

#if DEBUG
extension Satellite {
    func debugPlayback() -> Self {
        nowPlayingItemID = .fixture
        nowPlayingItem = Audiobook.fixture
        
        chapters = [
            .init(id: 0, startOffset: 0, endOffset: 100, title: "ABC"),
            .init(id: 1, startOffset: 101, endOffset: 200, title: "DEF"),
            .init(id: 2, startOffset: 201, endOffset: 300, title: "GHI"),
            .init(id: 3, startOffset: 301, endOffset: 400, title: "JKL"),
        ]
        
        isPlaying = true
        isBuffering = false
        
        currentTime = 20
        duration = 60
        
        currentChapterTime = 5
        chapterDuration = 10
        
        playbackRate = 1.5
        
        return self
    }
}
#endif
