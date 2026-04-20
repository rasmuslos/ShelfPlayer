//
//  Satellite.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.01.25.
//

import SwiftUI
import Combine
import AppIntents
import OSLog
import ShelfPlayback

@Observable @MainActor
final class Satellite {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Satellite")

    private let settings = AppSettings.shared

    // MARK: Navigation

    private(set) var sheetStack = [Sheet]()
    var warningAlertStack = [WarningAlert]()

    var settingsNavigationPath = NavigationPath()

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

    private(set) var busy = [ItemIdentifier: Int]()

    // MARK: Utility

    private(set) var totalLoading = 0

    var notifyError = false
    var notifySuccess = false

    private var persistentSubscriptions = Set<AnyCancellable>()
    private var observerSubscriptions = Set<AnyCancellable>()
    @ObservationIgnored
    private var areObserversRegistered = false

    // MARK: Init

    private init() {
        AppEventSource.shared.scenePhaseDidChange
            .sink { [weak self] isActive in
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    if isActive {
                        try await Task.sleep(for: .milliseconds(100))
                        self.setupObservers()
                        await self.syncAudioPlayerState()
                    } else {
                        self.unregisterObservers()
                    }
                }
            }
            .store(in: &persistentSubscriptions)

        PersistenceManager.shared.authorization.events.connectionUnauthorized
            .sink { [weak self] connectionID in
                Task { @MainActor [weak self] in
                    self?.present(.reauthorizeConnection(connectionID))
                }
            }
            .store(in: &persistentSubscriptions)

        NavigationEventSource.shared.setGlobalSearch
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.dismissSheet()
                }
            }
            .store(in: &persistentSubscriptions)

        #if DEBUG
        AppEventSource.shared.shake
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.present(.debug)
                }
            }
            .store(in: &persistentSubscriptions)
        #endif

        setupObservers()
    }

    // MARK: General Purpose

    enum SatelliteError: Error {
        case missingItem
    }

    public func isLoading(observing itemID: ItemIdentifier) -> Bool {
        totalLoading > 0 || busy[itemID] ?? 0 > 0 || itemID.isPlaceholder
    }

    private func startWorking(on itemID: ItemIdentifier) {
        let current = busy[itemID]

        withAnimation {
            if current == nil {
                busy[itemID] = 1
            } else {
                busy[itemID]! += 1
            }
        }
    }
    private func endWorking(on itemID: ItemIdentifier, successfully: Bool?) {
        guard let current = busy[itemID] else {
            logger.warning("Ending work on \(itemID, privacy: .public) but no longer busy")
            return
        }

        withAnimation {
            busy[itemID] = current - 1
        }

        if let successfully {
            if successfully {
                notifySuccess.toggle()
            } else {
                notifyError.toggle()
            }
        }
    }
}

// MARK: Sheet & Alert

extension Satellite {
    enum Sheet: Identifiable, Equatable {
        case listenNow

        case preferences
        case debugPreferences
        case customTabValuePreferences

        case description(Item)
        case configureGrouping(ItemIdentifier)

        case editCollection(ItemCollection)
        case editCollectionMembership(ItemIdentifier)

        case addConnection
        case editConnection(ItemIdentifier.ConnectionID)
        case reauthorizeConnection(ItemIdentifier.ConnectionID)

        case customizeLibrary(Library, PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope)
        case customizeHome(HomeScope, LibraryMediaType?)

        case whatsNew

        #if DEBUG
        case debug
        #endif

        var id: String {
            switch self {
                case .listenNow:
                    "listenNow"

                case .preferences:
                    "preferences"
                case .debugPreferences:
                    "debugPreferences"
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

                case .customizeLibrary(let library, let scope):
                    "customizeLibrary-\(library.id)-\(scope.id)"
                case .customizeHome(let scope, _):
                    "customizeHome-\(scope.key)"

                case .whatsNew:
                    "whatsNew"

                #if DEBUG
                case .debug:
                    "debug"
                #endif
            }
        }
    }
    enum WarningAlert {
        case message(String)

        case playbackStartWhileDownloading(ItemIdentifier)
        case downloadStartWhilePlaying
        case downloadRemoveWhilePlaying

        case convenienceDownloadManaged(ItemIdentifier)

        case termsOfServiceChanged

        var message: String {
            switch self {
                case .message(let message):
                    message

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

                case .playbackStartWhileDownloading, .downloadStartWhilePlaying, .downloadRemoveWhilePlaying:
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
        if sheetStack.first != .preferences {
            settingsNavigationPath = NavigationPath()
        }

        sheetStack.insert(sheet, at: 0)
    }
    func warn(_ warning: WarningAlert) {
        warningAlertStack.insert(warning, at: 0)
    }

    func dismissSheet() {
        guard !sheetStack.isEmpty else {
            return
        }

        if sheetStack.first == .preferences {
            settingsNavigationPath = NavigationPath()
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

                case .playbackStartWhileDownloading(let itemID):
                    do {
                        try await PersistenceManager.shared.download.remove(itemID)
                    } catch {
                        logger.warning("Failed to remove download before starting playback for \(itemID, privacy: .public): \(error, privacy: .public)")
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
                    settings.lastToSUpdate = ShelfPlayerKit.currentToSVersion
            }

            self.warningAlertStack.removeFirst()

            isLoadingAlert = false
        }
    }
}

// MARK: Bookmark

extension Satellite {
    func deleteBookmark(at time: UInt64, from itemID: ItemIdentifier) {
        Task {
            startWorking(on: itemID)

            do {
                try await PersistenceManager.shared.bookmark.delete(at: time, from: itemID)

                if nowPlayingItemID == itemID {
                    withAnimation {
                        bookmarks.removeAll {
                            $0.time == time
                        }
                    }
                }

                endWorking(on: itemID, successfully: true)
            } catch {
                logger.warning("Failed to delete bookmark at \(time, privacy: .public) for \(itemID, privacy: .public): \(error, privacy: .public)")
                endWorking(on: itemID, successfully: false)
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

    func play() {
        Task {
            await AudioPlayer.shared.play()
        }
    }
    func pause() {
        Task {
            await AudioPlayer.shared.pause()
        }
    }
    func togglePlaying() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func skip(forwards: Bool) {
        Task {
            guard let currentItemID = nowPlayingItemID else {
                return
            }

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
            } catch {
                logger.warning("Failed to skip item \(currentItemID, privacy: .public): \(error, privacy: .public)")
                notifyError.toggle()
            }
        }
    }
    func seek(to time: TimeInterval, insideChapter: Bool, completion: (@Sendable @escaping () -> Void)) {
        Task {
            guard let currentItemID = nowPlayingItemID else {
                return
            }

            do {
                try await AudioPlayer.shared.seek(to: time, insideChapter: insideChapter)
                completion()
            } catch {
                logger.warning("Failed to seek item \(currentItemID, privacy: .public) to \(time, privacy: .public): \(error, privacy: .public)")
                notifyError.toggle()
            }
        }
    }

    func start(_ itemID: ItemIdentifier, at: TimeInterval? = nil, origin: AudioPlayerItem.PlaybackOrigin = .unknown, queue: [ItemIdentifier] = []) {
        Task {
            guard self.nowPlayingItemID != itemID else {
                togglePlaying()
                return
            }

            guard await PersistenceManager.shared.download.status(of: itemID) != .downloading else {
                warn(.playbackStartWhileDownloading(itemID))
                return
            }

            guard !isLoading(observing: itemID) else {
                return
            }

            startWorking(on: itemID)

            do {
                try await AudioPlayer.shared.start(.init(itemID: itemID, origin: origin))

                if let at {
                    try await AudioPlayer.shared.seek(to: at, insideChapter: false)
                }

                try await AudioPlayer.shared.queue(queue.map { .init(itemID: $0, origin: .unknown) })

                endWorking(on: itemID, successfully: true)
            } catch {
                logger.warning("Failed to start playback for \(itemID, privacy: .public): \(error, privacy: .public)")
                endWorking(on: itemID, successfully: false)
            }
        }
    }
    func stop() {
        Task {
            guard let currentItemID = nowPlayingItemID else {
                return
            }

            startWorking(on: currentItemID)
            await AudioPlayer.shared.stop()
            endWorking(on: currentItemID, successfully: true)
        }
    }

    func queue(_ itemID: ItemIdentifier) {
        Task {
            startWorking(on: itemID)

            do {
                try await AudioPlayer.shared.queue([.init(itemID: itemID, origin: .unknown)])
                endWorking(on: itemID, successfully: true)
            } catch {
                logger.warning("Failed to queue item \(itemID, privacy: .public): \(error, privacy: .public)")
                endWorking(on: itemID, successfully: false)
            }
        }
    }
    func queue(_ itemIDs: [ItemIdentifier], origin: AudioPlayerItem.PlaybackOrigin = .unknown) {
        Task {
            withAnimation {
                totalLoading += 1
            }

            do {
                try await AudioPlayer.shared.queue(itemIDs.map { .init(itemID: $0, origin: origin) })

                notifySuccess.toggle()
            } catch {
                logger.warning("Failed to queue \(itemIDs.count, privacy: .public) item(s): \(error, privacy: .public)")
                notifyError.toggle()
            }

            withAnimation {
                totalLoading -= 1
            }
        }
    }

    func setPlaybackRate(_ rate: Percentage) {
        Task {
            await AudioPlayer.shared.setPlaybackRate(rate)

            do {
                try await SetPlaybackRateIntent(rate: rate).donate()
            } catch {
                logger.error("Failed to donate SetPlaybackRateIntent: \(error)")
            }

            notifySuccess.toggle()
        }
    }

    func setSleepTimer(_ configuration: SleepTimerConfiguration?) {
        Task {
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

                notifySuccess.toggle()
            } catch {
                logger.error("Failed to donate SetSleepTimerIntent: \(error)")
            }

        }
    }
    func extendSleepTimer() {
        Task {
            await AudioPlayer.shared.extendSleepTimer()

            do {
                try await ExtendSleepTimerIntent().donate()
            } catch {
                logger.error("Failed to donate ExtendSleepTimerIntent: \(error)")
            }

            notifySuccess.toggle()
        }
    }
    func setSleepTimerToChapter(_ chapter: Chapter) {
        Task {
            guard let currentItemID = nowPlayingItemID else {
                return
            }

            let chapters = await AudioPlayer.shared.chapters

            guard let index = chapters.firstIndex(of: chapter),
                  let currentChapterIndex = await AudioPlayer.shared.activeChapterIndex,
                  index >= currentChapterIndex else {
                endWorking(on: currentItemID, successfully: false)
                return
            }

            let amount = index - currentChapterIndex + 1

            await AudioPlayer.shared.setSleepTimer(.chapters(amount, 1))

            do {
                try await SetSleepTimerIntent(amount: amount, type: .chapters).donate()
            } catch {
                logger.error("Failed to donate ExtendSleepTimerIntent: \(error)")
            }

            notifySuccess.toggle()
        }
    }

    func skip(queueIndex index: Int) {
        Task {
            await AudioPlayer.shared.skip(queueIndex: index)
            notifySuccess.toggle()
        }
    }
    func skip(upNextQueueIndex index: Int) {
        Task {
            await AudioPlayer.shared.skip(upNextQueueIndex: index)
            notifySuccess.toggle()
        }
    }

    func move(queueIndex: IndexSet, to: Int) {
        Task {
            await AudioPlayer.shared.move(queueIndex: queueIndex, to: to)
            notifySuccess.toggle()
        }
    }

    func remove(queueIndex index: Int) {
        Task {
            await AudioPlayer.shared.remove(queueIndex: index)
            notifySuccess.toggle()
        }
    }
    func remove(upNextQueueIndex index: Int) {
        Task {
            await AudioPlayer.shared.remove(upNextQueueIndex: index)
            notifySuccess.toggle()
        }
    }

    func clearQueue() {
        Task {
            await AudioPlayer.shared.clearQueue()
            notifySuccess.toggle()
        }
    }
    func clearUpNextQueue() {
        Task {
            await AudioPlayer.shared.clearUpNextQueue()
            notifySuccess.toggle()
        }
    }
}

// MARK: Progress

extension Satellite {
    func markAsFinished(_ itemID: ItemIdentifier) {
        Task {
            startWorking(on: itemID)

            do {
                if nowPlayingItemID == itemID {
                    try await AudioPlayer.shared.seek(to: duration, insideChapter: false)
                } else {
                    try await PersistenceManager.shared.progress.markAsCompleted(itemID)
                }

                endWorking(on: itemID, successfully: true)
            } catch {
                logger.warning("Failed to mark \(itemID, privacy: .public) as finished: \(error, privacy: .public)")
                endWorking(on: itemID, successfully: false)
            }
        }
    }
    func markAsUnfinished(_ itemID: ItemIdentifier) {
        Task {
            startWorking(on: itemID)

            do {
                try await PersistenceManager.shared.progress.markAsListening(itemID)
                endWorking(on: itemID, successfully: true)
            } catch {
                logger.warning("Failed to mark \(itemID, privacy: .public) as unfinished: \(error, privacy: .public)")
                endWorking(on: itemID, successfully: false)
            }
        }
    }
    func deleteProgress(_ itemID: ItemIdentifier) {
        Task {
            startWorking(on: itemID)

            do {
                try await PersistenceManager.shared.progress.delete(itemID: itemID)
                endWorking(on: itemID, successfully: true)
            } catch {
                logger.warning("Failed to delete progress for \(itemID, privacy: .public): \(error, privacy: .public)")
                endWorking(on: itemID, successfully: false)
            }
        }
    }
}

// MARK: Download

extension Satellite {
    func download(itemID: ItemIdentifier) {
        Task {
            let status = await PersistenceManager.shared.download.status(of: itemID)

            guard status == .none else {
                return
            }

            guard await AudioPlayer.shared.currentItemID != itemID else {
                warn(.downloadStartWhilePlaying)
                return
            }
            startWorking(on: itemID)

            do {
                try await PersistenceManager.shared.download.download(itemID)
                endWorking(on: itemID, successfully: true)
            } catch {
                logger.error("Failed to download item \(itemID, privacy: .public): \(error)")
                endWorking(on: itemID, successfully: false)
            }
        }
    }

    func removeDownload(itemID: ItemIdentifier, force: Bool) {
        Task {
            if !force {
                guard nowPlayingItemID != itemID else {
                    warn(.downloadRemoveWhilePlaying)
                    return
                }

                guard await !PersistenceManager.shared.convenienceDownload.isManaged(itemID: itemID) else {
                    warn(.convenienceDownloadManaged(itemID))
                    return
                }
            }

            do {
                try await PersistenceManager.shared.download.remove(itemID)

                notifySuccess.toggle()
            } catch {
                logger.warning("Failed to remove download for \(itemID, privacy: .public): \(error, privacy: .public)")
                notifyError.toggle()
            }
        }
    }
    func removeConvenienceDownloadConfigurations(from itemID: ItemIdentifier) {
        Task {
            startWorking(on: itemID)

            await PersistenceManager.shared.convenienceDownload.removeConfigurations(associatedWith: itemID)
            removeDownload(itemID: itemID, force: true)

            endWorking(on: itemID, successfully: true)
        }
    }
}

// MARK: Private

private extension Satellite {
    func resolvePlayingItem() {
        Task {
            guard let currentItemID = nowPlayingItemID else {
                withAnimation {
                    self.nowPlayingItem = nil
                }

                return
            }

            do {
                guard let item = try await currentItemID.resolved as? PlayableItem else {
                    throw SatelliteError.missingItem
                }

                self.nowPlayingItem = item
            } catch {
                logger.warning("Failed to resolve now playing item \(currentItemID, privacy: .public): \(error, privacy: .public)")
                self.notifyError.toggle()
            }
        }
    }
    func loadBookmarks(itemID: ItemIdentifier) {
        Task {
            do {
                guard itemID.type == .audiobook else {
                    throw CancellationError()
                }

                let bookmarks = try await PersistenceManager.shared.bookmark[itemID]

                withAnimation {
                    self.bookmarks = bookmarks
                }
            } catch {
                logger.warning("Failed to load bookmarks for \(itemID, privacy: .public): \(error, privacy: .public)")
                withAnimation {
                    self.bookmarks = []
                }
            }
        }
    }

    // MARK: Observers

    func setupObservers() {
        guard !areObserversRegistered else {
            return
        }

        logger.info("Setting up Satellite observers")
        areObserversRegistered = true

        // MARK: General

        OfflineMode.events.changed
            .sink { _ in
                Task.detached {
                    await ShelfPlayer.invalidateShortTermCache()
                }
            }
            .store(in: &observerSubscriptions)

        NavigationEventSource.shared.navigate
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.dismissSheet()
                }
            }
            .store(in: &observerSubscriptions)

        // MARK: Audio Player state synchronization

        AudioPlayer.shared.events.playbackItemChanged
            .sink { [weak self] itemID, chapters, startTime in
                Task { @MainActor [weak self] in
                    self?.nowPlayingItemID = itemID
                    self?.nowPlayingItem = nil

                    self?.chapters = chapters

                    self?.isPlaying = false
                    self?.isBuffering = true

                    self?.currentTime = startTime
                    self?.currentChapterTime = 0

                    self?.duration = 0
                    self?.chapterDuration = 0

                    self?.playbackRate = 0

                    self?.route = nil
                    self?.sleepTimer = nil

                    self?.upNextOrigin = nil
                    self?.upNextStrategy = nil

                    self?.resolvePlayingItem()
                    self?.loadBookmarks(itemID: itemID)
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.playStateChanged
            .sink { [weak self] isPlaying in
                Task { @MainActor [weak self] in
                    self?.notifySuccess.toggle()
                    self?.isPlaying = isPlaying
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.skipped
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.notifySuccess.toggle()
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.bufferHealthChanged
            .sink { [weak self] isBuffering in
                Task { @MainActor [weak self] in
                    self?.isBuffering = isBuffering
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.durationsChanged
            .sink { [weak self] durations in
                Task { @MainActor [weak self] in
                    self?.duration = durations.0 ?? 0
                    self?.chapterDuration = durations.1 ?? self?.duration ?? 0
                }
            }
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.currentTimesChanged
            .sink { [weak self] currentTimes in
                Task { @MainActor [weak self] in
                    self?.currentTime = currentTimes.0 ?? 0
                    self?.currentChapterTime = currentTimes.1 ?? self?.currentTime ?? 0
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.chapterChanged
            .sink { [weak self] chapter in
                Task { @MainActor [weak self] in
                    self?.chapter = chapter
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.volumeChanged
            .sink { [weak self] volume in
                Task { @MainActor [weak self] in
                    self?.volume = volume
                }
            }
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.playbackRateChanged
            .sink { [weak self] playbackRate in
                Task { @MainActor [weak self] in
                    self?.playbackRate = playbackRate
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.routeChanged
            .sink { [weak self] route in
                Task { @MainActor [weak self] in
                    self?.route = route
                }
            }
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.sleepTimerChanged
            .sink { [weak self] sleepTimer in
                Task { @MainActor [weak self] in
                    self?.sleepTimer = sleepTimer
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.queueChanged
            .sink { [weak self] queue in
                Task { @MainActor [weak self] in
                    self?.queue = queue
                }
            }
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.upNextQueueChanged
            .sink { [weak self] upNextQueue in
                Task { @MainActor [weak self] in
                    self?.upNextQueue = upNextQueue
                }
            }
            .store(in: &observerSubscriptions)
        AudioPlayer.shared.events.upNextStrategyChanged
            .sink { [weak self] strategy in
                Task { @MainActor [weak self] in
                    self?.upNextStrategy = strategy
                    self?.resolveUpNextOrigin()
                }
            }
            .store(in: &observerSubscriptions)

        AudioPlayer.shared.events.playbackStopped
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
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
                }
            }
            .store(in: &observerSubscriptions)

        PersistenceManager.shared.bookmark.events.changed
            .sink { [weak self] itemID in
                Task { @MainActor [weak self] in
                    guard let self, self.nowPlayingItemID == itemID else {
                        return
                    }

                    self.loadBookmarks(itemID: itemID)
                }
            }
            .store(in: &observerSubscriptions)
    }
    func unregisterObservers() {
        guard areObserversRegistered else {
            return
        }

        logger.info("Unregistering Satellite observers")
        observerSubscriptions.removeAll(keepingCapacity: true)
        areObserversRegistered = false
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

        if let nowPlayingItemID {
            loadBookmarks(itemID: nowPlayingItemID)
        }
    }

    func resolveUpNextOrigin() {
        Task {
            let upNextStrategy = upNextStrategy
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

            withAnimation {
                self.upNextOrigin = origin
            }
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
