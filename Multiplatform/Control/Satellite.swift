//
//  Satellite.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.01.25.
//

import SwiftUI
import AppIntents
import OSLog
import ShelfPlayback

@Observable @MainActor
final class Satellite {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Satellite")
    
    // MARK: Navigation
    
    private(set) var isOffline = Defaults[.startInOfflineMode]
    
    var tabValue: TabValue?
    
    private(set) var sheetStack = [Sheet]()
    var warningAlertStack = [WarningAlert]()
    
    private(set) var isLoadingAlert = false

    // MARK: Playback
    
    private(set) var nowPlayingItemID: ItemIdentifier?
    private(set) var nowPlayingItem: PlayableItem?
    
    private(set) var queue = [ItemIdentifier]()
    private(set) var upNextQueue = [ItemIdentifier]()
    
    private(set) var chapter: Chapter?
    private(set) var chapters = [Chapter]()
    
    private(set) var isPlaying = false
    private(set) var isBuffering = true
    
    private(set) var currentTime = 0.0
    private(set) var currentChapterTime = 0.0
    
    private(set) var duration = 0.0
    private(set) var chapterDuration = 0.0
    
    private(set) var volume = 0.0
    private(set) var playbackRate = 0.0
    
    private(set) var route: AudioRoute?
    private(set) var sleepTimer: SleepTimerConfiguration?
    
    private(set) var upNextOrigin: Item?
    private(set) var upNextStrategy: ResolvedUpNextStrategy?
    
    private(set) var bookmarks = [Bookmark]()
    
    // MARK: Playback helper
    
    private(set) var skipCache: TimeInterval?
    private(set) var remainingSleepTime: Double?
    private(set) var busy = [ItemIdentifier: Int]()
    
    @ObservationIgnored
    private(set) nonisolated(unsafe) var skipTask: Task<Void, Never>?
    
    private(set) var notifySkipBackwards = false
    private(set) var notifySkipForwards = false
    
    // MARK: Utility
    
    private(set) var totalLoading = 0
    
    var notifyError = false
    var notifySuccess = false
    
    private var stash = RFNotification.MarkerStash()
    
    // MARK: Init
    
    private init() {
        RFNotification[.scenePhaseDidChange].subscribe { [weak self] in
            if $0 {
                self?.setupObservers()
                
                Task {
                    await self?.syncAudioPlayerState()
                }
            } else {
                self?.stash.clear()
            }
        }
        
        RFNotification[.presentSheet].subscribe { [weak self] in
            self?.present($0)
        }
        
        setupObservers()
        checkForResumablePlayback()
        
        // MARK: What's New
        
        if WhatsNewSheet.shouldDisplay {
            present(.whatsNew)
        }
    }
    
    // MARK: General Purpose
    
    enum SatelliteError: Error {
        case missingItem
    }

    public func isLoading(observing itemID: ItemIdentifier) -> Bool {
        totalLoading > 0 || busy[itemID] ?? 0 > 0 || itemID.primaryID == "placeholder"
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
        case customTabValuePreferences
        
        case description(Item)
        case configureGrouping(ItemIdentifier)
        
        case editCollection(ItemCollection)
        case editCollectionMembership(ItemIdentifier)
        
        case addConnection
        case editConnection(ItemIdentifier.ConnectionID)
        case reauthorizeConnection(ItemIdentifier.ConnectionID)
        
        case whatsNew
        
        var id: String {
            switch self {
                case .listenNow:
                    "listenNow"
                case .preferences:
                    "preferences"
                case .customTabValuePreferences:
                    "customTabValuePreferences"
                case .description(let item):
                    "description-\(item.id)"
                case .configureGrouping(let itemID):
                    "configureGrouping-\(itemID)"
                case .editCollection(let collection):
                    "editCollection-\(collection.id)"
                case .editCollectionMembership(let itemID):
                    "editCollectionMembership-\(itemID)"
                case .addConnection:
                    "addConnection"
                case .editConnection(let connectionID):
                    "editConnection-\(connectionID)"
                case .reauthorizeConnection(let connectionID):
                    "reauthorizeConnection-\(connectionID)"
                case .whatsNew:
                    "whatsNew"
            }
        }
    }
    enum WarningAlert {
        case message(String)
        
        case resumePlayback(ItemIdentifier)
        
        case playbackStartWhileDownloading(ItemIdentifier)
        case downloadStartWhilePlaying
        case downloadRemoveWhilePlaying
        
        case convenienceDownloadManaged(ItemIdentifier)
        
        case termsOfServiceChanged
        
        var message: String {
            switch self {
                case .message(let message):
                    message
                    
                case .resumePlayback:
                    String(localized: "playback.alert.resume.message")
                    
                case .playbackStartWhileDownloading:
                    String(localized: "warning.playbackDownload.activeDownload")
                case .downloadStartWhilePlaying:
                    String(localized: "warning.playbackDownload.activePlayback")
                case .downloadRemoveWhilePlaying:
                    String(localized: "warning.playbackDownload.removeDownload")
                    
                case .convenienceDownloadManaged:
                    String(localized: "warning.convenienceDownloadManaged")
                    
                case .termsOfServiceChanged:
                    "ShelfPlayer's Terms of Service and Privacy Policy have been updated to better align with legal requirements. Please take a moment to review the revised documents to continue using the app. There are no changes to app functionality, and our privacy practices remain unchanged."
            }
        }
        
        var actions: [WarningAction] {
            switch self {
                case .message:
                    [.dismiss]
                    
                case .resumePlayback, .playbackStartWhileDownloading, .downloadStartWhilePlaying, .downloadRemoveWhilePlaying:
                    [.cancel, .proceed]
                    
                case .convenienceDownloadManaged(let itemID):
                    [.cancel, .removeConvenienceDownloadConfigurations(itemID), .proceed]
                    
                case .termsOfServiceChanged:
                    [.acknowledge, .learnMore(URL(string: "https://github.com/rasmuslos/ShelfPlayer/issues/320")!)]
            }
        }
        
        enum WarningAction: Identifiable, Hashable, Equatable, Codable {
            case cancel
            case proceed
            case dismiss
            case acknowledge
            
            // Special
            
            case learnMore(URL)
            case removeConvenienceDownloadConfigurations(ItemIdentifier)
            
            var id: String {
                switch self {
                    case .proceed:
                        "G_proceed"
                    case .acknowledge:
                        "H_acknowledge"
                    case .learnMore(let url):
                        "I_learnMore_\(url.absoluteString)"
                    case .removeConvenienceDownloadConfigurations(let itemID):
                        "J_removeConvenienceDownloadConfigurations_\(itemID)"
                    case .dismiss:
                        "Q_dissmiss"
                    case .cancel:
                        "Z_cancel"
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
                self.dismissSheet()
            }
        }
    }
    var isWarningAlertPresented: Binding<Bool> {
        .init {
            !self.warningAlertStack.isEmpty
        } set: { _ in }
    }
    
    func present(_ sheet: Sheet) {
        sheetStack.insert(sheet, at: 0)
    }
    func warn(_ warning: WarningAlert) {
        warningAlertStack.insert(warning, at: 0)
    }
    
    func dismissSheet() {
        guard !sheetStack.isEmpty else {
            return
        }
        
        sheetStack.removeFirst()
    }
    func dismissSheet(id: String) {
        sheetStack.removeAll { $0.id == id }
    }

    func cancelWarningAlert() {
        guard !warningAlertStack.isEmpty else {
            return
        }
        
        warningAlertStack.removeFirst()
    }
    func confirmWarningAlert() {
        guard let warningAlert = warningAlertStack.first else {
            return
        }
        
        Task {
            isLoadingAlert = true
            
            switch warningAlert {
                case .message:
                    break
                    
                case .resumePlayback(let itemID):
                    start(itemID, queue: Defaults[.playbackResumeQueue])
                    
                case .playbackStartWhileDownloading(let itemID):
                    do {
                        try await PersistenceManager.shared.download.remove(itemID)
                    } catch {
                        notifyError.toggle()
                    }
                    
                    start(itemID)
                case .downloadStartWhilePlaying:
                    guard let nowPlayingItemID else {
                        notifyError.toggle()
                        return
                    }
                    
                    await AudioPlayer.shared.stop()
                    download(itemID: nowPlayingItemID)
                case .downloadRemoveWhilePlaying:
                    guard let nowPlayingItemID else {
                        notifyError.toggle()
                        return
                    }
                    
                    await AudioPlayer.shared.stop()
                    removeDownload(itemID: nowPlayingItemID, force: false)
                    
                case .convenienceDownloadManaged(let itemID):
                    removeDownload(itemID: itemID, force: true)
                    
                case .termsOfServiceChanged:
                    Defaults[.lastToSUpdate] = ShelfPlayerKit.currentToSVersion
            }
            
            self.warningAlertStack.removeFirst()
            
            isLoadingAlert = false
        }
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
            
            do {
                try await PlayIntent().donate()
            } catch {
                logger.error("Failed to donate ExtendSleepTimerIntent: \(error)")
            }
            
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
            
            do {
                try await PauseIntent().donate()
            } catch {
                logger.error("Failed to donate ExtendSleepTimerIntent: \(error)")
            }
            
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
                
                let intent: any AppIntent
                
                if forwards {
                    intent = SkipForwardsIntent()
                } else {
                    intent = SkipBackwardsIntent()
                }
                
                do {
                    try await intent.donate()
                } catch {
                    logger.error("Failed to donate skip intent: \(error)")
                }
                
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
        
        if forwards {
            notifySkipForwards.toggle()
        } else {
            notifySkipBackwards.toggle()
        }

        skipTask?.cancel()
        skipTask = Task {
            try? await Task.sleep(for: .seconds(isInitial ? 0.3 : 0.7))

            guard !Task.isCancelled else {
                return
            }

            if let skipCache {
                self.skipCache = nil
                seek(to: currentTime + skipCache, insideChapter: false) {}
            }
        }
    }

    nonisolated func start(_ itemID: ItemIdentifier, at: TimeInterval? = nil, origin: AudioPlayerItem.PlaybackOrigin = .unknown, queue: [ItemIdentifier] = []) {
        Task {
            guard await self.nowPlayingItemID != itemID else {
                await togglePlaying()
                return
            }
            
            guard await PersistenceManager.shared.download.status(of: itemID) != .downloading else {
                await warn(.playbackStartWhileDownloading(itemID))
                return
            }

            await startWorking(on: itemID)

            do {
                try await AudioPlayer.shared.start(.init(itemID: itemID, origin: origin, startWithoutListeningSession: isOffline))
                
                if let at {
                    try await AudioPlayer.shared.seek(to: at, insideChapter: false)
                }
                
                let isOffline = await isOffline
                try await AudioPlayer.shared.queue(queue.map { .init(itemID: $0, origin: .unknown, startWithoutListeningSession: isOffline) })
                
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
                try await AudioPlayer.shared.queue([.init(itemID: itemID, origin: .unknown, startWithoutListeningSession: isOffline)])
                await endWorking(on: itemID, successfully: true)
            } catch {
                await endWorking(on: itemID, successfully: false)
            }
        }
    }
    nonisolated func queue(_ itemIDs: [ItemIdentifier], origin: AudioPlayerItem.PlaybackOrigin = .unknown) {
        Task {
            await MainActor.withAnimation {
                totalLoading += 1
            }

            do {
                let isOffline = await isOffline
                try await AudioPlayer.shared.queue(itemIDs.map { .init(itemID: $0, origin: origin, startWithoutListeningSession: isOffline) })
                
                await MainActor.run {
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                totalLoading -= 1
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
            
            do {
                try await SetPlaybackRateIntent(rate: rate).donate()
            } catch {
                logger.error("Failed to donate SetPlaybackRateIntent: \(error)")
            }
            
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
            
            do {
                switch configuration {
                    case .interval(let deadline, _):
                        let distance = Date.now.distance(to: deadline) / 60
                        try await SetSleepTimerIntent(amount: Int(distance), type: .minutes).donate()
                    case .chapters(let amount, _):
                        try await SetSleepTimerIntent(amount: amount, type: .chapters).donate()
                    default:
                        break
                }
            } catch {
                logger.error("Failed to donate SetSleepTimerIntent: \(error)")
            }
            
            await resolveRemainingSleepTime()
            
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
            
            do {
                try await ExtendSleepTimerIntent().donate()
            } catch {
                logger.error("Failed to donate ExtendSleepTimerIntent: \(error)")
            }
            
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

            await AudioPlayer.shared.setSleepTimer(.chapters(amount, 1))
            
            do {
                try await SetSleepTimerIntent(amount: amount, type: .chapters).donate()
            } catch {
                logger.error("Failed to donate ExtendSleepTimerIntent: \(error)")
            }
            
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
    
    nonisolated func move(queueIndex: IndexSet, to: Int) {
        Task {
            guard let currentItemID = await nowPlayingItemID else {
                return
            }

            await startWorking(on: currentItemID)
            await AudioPlayer.shared.move(queueIndex: queueIndex, to: to)
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
                    try await PersistenceManager.shared.progress.markAsCompleted([itemID])
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
                try await PersistenceManager.shared.progress.markAsListening([itemID])
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
    nonisolated func download(itemID: ItemIdentifier) {
        Task {
            let status = await PersistenceManager.shared.download.status(of: itemID)

            guard status == .none else {
                return
            }
            
            guard await AudioPlayer.shared.currentItemID != itemID else {
                await warn(.downloadStartWhilePlaying)
                return
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
    
    nonisolated func removeDownload(itemID: ItemIdentifier, force: Bool) {
        Task {
            if !force {
                guard await nowPlayingItemID != itemID else {
                    await warn(.downloadRemoveWhilePlaying)
                    return
                }
                
                guard await !PersistenceManager.shared.convenienceDownload.isManaged(itemID: itemID) else {
                    await warn(.convenienceDownloadManaged(itemID))
                    return
                }
            }
            
            do {
                try await PersistenceManager.shared.download.remove(itemID)
                
                await MainActor.run {
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
        }
    }
    nonisolated func removeConvenienceDownloadConfigurations(from itemID: ItemIdentifier) {
        Task {
            await startWorking(on: itemID)
            
            await PersistenceManager.shared.convenienceDownload.removeConfigurations(associatedWith: itemID)
            removeDownload(itemID: itemID, force: true)
            
            await endWorking(on: itemID, successfully: true)
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
            
            do {
                guard let item = try await currentItemID.resolved as? PlayableItem else {
                    throw SatelliteError.missingItem
                }
                
                await MainActor.run {
                    self.nowPlayingItem = item
                }
            } catch {
                await MainActor.run {
                    self.notifyError.toggle()
                }
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
        
        guard !Defaults[.disableResumeListening] else {
            return
        }
        
        // 12 Hours
        let timeout: Double = 60 * 60 * 12
        
        guard playbackResumeInfo.started.distance(to: .now) < timeout else {
            return
        }
        
        warn(.resumePlayback(playbackResumeInfo.itemID))
    }

    // MARK: Observers

    func setupObservers() {
        stash.clear()
        
        // MARK: General
        
        RFNotification[.changeOfflineMode].subscribe { [weak self] in
            if $0 {
                let appearance = UINavigationBarAppearance()
                
                appearance.configureWithTransparentBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().compactAppearance = appearance
            }
            
            Task.detached {
                await ShelfPlayer.invalidateShortTermCache()
            }
            
            self?.isOffline = $0
        }.store(in: &stash)
        
        RFNotification[.navigate].subscribe { [weak self] _ in
            self?.dismissSheet()
        }.store(in: &stash)
        
        // MARK: Audio Player state synchronization
        
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
            
            self?.upNextOrigin = nil
            self?.upNextStrategy = nil
            
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
            
            self?.resolveRemainingSleepTime()
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
        RFNotification[.upNextStrategyChanged].subscribe { [weak self] strategy in
            self?.upNextStrategy = strategy
            self?.resolveUpNextOrigin()
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
            
            self?.upNextOrigin = nil
            self?.upNextStrategy = nil
            
            self?.bookmarks = []
        }.store(in: &stash)
        
        RFNotification[.bookmarksChanged].subscribe { [weak self] itemID in
            guard self?.nowPlayingItemID == itemID else {
                return
            }
            
            self?.loadBookmarks(itemID: itemID)
        }.store(in: &stash)
    }
    
    func syncAudioPlayerState() async {
        nowPlayingItemID = await AudioPlayer.shared.currentItemID
        
        queue = await AudioPlayer.shared.queue.map(\.itemID)
        upNextQueue = await AudioPlayer.shared.upNextQueue.map(\.itemID)
        
        if let activeChapterIndex = await AudioPlayer.shared.activeChapterIndex {
            chapter = await AudioPlayer.shared.chapters[activeChapterIndex]
        } else {
            chapter = nil
        }
        
        chapters = await AudioPlayer.shared.chapters
        
        isPlaying = await AudioPlayer.shared.isPlaying
        isBuffering = await AudioPlayer.shared.isBusy
        
        currentTime = await AudioPlayer.shared.currentTime ?? 0
        currentChapterTime = await AudioPlayer.shared.chapterCurrentTime ?? 0
        
        duration = await AudioPlayer.shared.duration ?? 0
        chapterDuration = await AudioPlayer.shared.chapterDuration ?? 0
        
        playbackRate = await AudioPlayer.shared.playbackRate
        
        route = await AudioPlayer.shared.route
        sleepTimer = await AudioPlayer.shared.sleepTimer
        
        upNextStrategy = await AudioPlayer.shared.upNextStrategy
        
        resolveUpNextOrigin()
        resolvePlayingItem()
        resolveRemainingSleepTime()
        
        if let nowPlayingItemID {
            loadBookmarks(itemID: nowPlayingItemID)
        }
    }
    
    nonisolated func resolveUpNextOrigin() {
        Task {
            let upNextStrategy = await upNextStrategy
            let origin: Item?
            
            switch upNextStrategy {
                case .series(let itemID):
                    origin = try? await itemID.resolved
                case .podcast(let itemID):
                    origin = try? await itemID.resolved
                case .collection(let itemID):
                    origin = try? await itemID.resolved
                default:
                    origin = nil
            }
            
            await MainActor.withAnimation {
                self.upNextOrigin = origin
            }
        }
    }
    func resolveRemainingSleepTime() {
        if let sleepTimer = sleepTimer, case .interval(let date, _) = sleepTimer {
            remainingSleepTime = Date.now.distance(to: date)
        }
    }
}

extension Satellite {
    static let shared = Satellite()
}

// MARK: Debug fixture

#if DEBUG
extension Satellite {
    func debugPlayback() -> Self {
        nowPlayingItemID = .fixture
//        nowPlayingItem = Audiobook.fixture
        nowPlayingItem = Episode.fixture
        
        chapters = [
            .init(id: 0, startOffset: 0, endOffset: 100, title: "ABC"),
            .init(id: 1, startOffset: 101, endOffset: 200, title: "DEF"),
            .init(id: 2, startOffset: 201, endOffset: 300, title: "GHI"),
            .init(id: 3, startOffset: 301, endOffset: 400, title: "JKL"),
        ]
        chapters = (Int(0)...100).map {
            .init(id: $0, startOffset: Double($0), endOffset: Double($0) + 0.99, title: "\($0)")
        }
        
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
