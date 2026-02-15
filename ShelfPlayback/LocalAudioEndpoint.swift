//
//  LocalAudioEndpoint.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation
import Combine
@preconcurrency import AVKit
import MediaPlayer
import OSLog
import ShelfPlayerKit

@MainActor
final class LocalAudioEndpoint: AudioEndpoint {
    nonisolated let id = UUID()
    
    private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "LocalAudioEndpoint")
    
    private let audioPlayer: AVQueuePlayer
    
    private var playbackReporter: PlaybackReporter!
    
    private(set) var currentItem: AudioPlayerItem
    
    private(set) var queue: [AudioPlayerItem] {
        didSet {
            Defaults[.playbackResumeQueue] = queue.map(\.itemID)
        }
    }
    private(set) var upNextQueue: [AudioPlayerItem] {
        didSet {
            if upNextQueue.isEmpty {
                upNextStrategy = nil
                
                Task.detached {
                    await AudioPlayer.shared.upNextStrategyDidChange(endpointID: self.id, strategy: nil)
                }
            }
        }
    }
    
    private(set) var audioTracks: [PlayableItem.AudioTrack]
    private(set) var activeAudioTrackIndex: Int
    
    private(set) var chapters: [Chapter]
    private(set) var activeChapterIndex: Int? {
        didSet {
            guard let oldValue else {
                return
            }
            
            if oldValue + 1 == activeChapterIndex {
                Task {
                    await sleepChapterDidEnd()
                }
            }
        }
    }
    
    private(set) var isPlaying: Bool
    
    private(set) var isBuffering: Bool
    private(set) var activeOperationCount: Int {
        didSet {
            updateBufferingCheckTaskSchedule()
            
            Task {
                await AudioPlayer.shared.isBusyDidChange()
            }
        }
    }
    
    private(set) var systemVolume: Percentage
    
    private(set) var duration: TimeInterval?
    private(set) var currentTime: TimeInterval?
    
    private(set) var chapterDuration: TimeInterval?
    private(set) var chapterCurrentTime: TimeInterval?
    
    private(set) var route: AudioRoute? {
        didSet {
            if let route {
                Task {
                    await AudioPlayer.shared.routeDidChange(endpointID: id, route: route)
                }
            }
        }
    }
    private(set) var sleepTimer: SleepTimerConfiguration? {
        didSet {
            updateSleepTimerSchedule()
            
            Task {
                await AudioPlayer.shared.sleepTimerDidChange(endpointID: id, configuration: sleepTimer)
            }
        }
    }
    
    private(set) var upNextStrategy: ResolvedUpNextStrategy?
    
    private var chapterValidUntil: TimeInterval?
    
    private var audioPlayerSubscription: Any?
    private var volumeSubscription: AnyCancellable?
    private var bufferCheckTimer: Timer?
    
    private var sleepLastPause: Date?
    private var sleepTimeoutTimer: Timer?
    
    private var allowUpNextQueueGeneration: Bool
    
    let audioPlayerVolume: Float = 1
    
    init(_ item: AudioPlayerItem) async throws {
        logger.info("Starting up local audio endpoint with item ID \(item.itemID))")
        
        playbackReporter = nil
        audioPlayer = .init()
        
        audioPlayer.allowsExternalPlayback = false
        
        currentItem = item
        
        queue = .init()
        upNextQueue = .init()
        
        audioTracks = []
        activeAudioTrackIndex = -1
        
        chapters = []
        activeChapterIndex = nil
        
        isPlaying = false
        
        isBuffering = true
        activeOperationCount = 0
        
        systemVolume = 0
        
        duration = nil
        currentTime = nil
        
        chapterDuration = nil
        chapterCurrentTime = nil
        
        route = nil
        
        allowUpNextQueueGeneration = true
        
        await setupObservers()
        
        try await start()
    }
    deinit {
        // bufferCheckTimer?.invalidate()
    }
    
    var currentItemID: ItemIdentifier {
        currentItem.itemID
    }
    
    var seriesID: ItemIdentifier? {
        get async {
            guard currentItemID.type == .audiobook else {
                return nil
            }
            
            if case .series(let seriesID) = currentItem.origin {
                return seriesID
            } else if let resolved = try? await currentItemID.resolved as? Audiobook, let seriesID = resolved.series.first?.id {
                return seriesID
            } else {
                return nil
            }
        }
    }
    var podcastID: ItemIdentifier? {
        get async {
            guard currentItemID.type == .episode else {
                return nil
            }
            
            return ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(currentItemID)
        }
    }
    var collectionID: ItemIdentifier? {
        get async {
            guard case .collection(let collectionID) = currentItem.origin else {
                return nil
            }
            
            return collectionID
        }
    }
    
    var groupingID: ItemIdentifier? {
        get async {
            if let collectionID = await collectionID {
                collectionID
            } else if let seriesID = await seriesID {
                seriesID
            } else if let podcastID = await podcastID {
                podcastID
            } else {
                nil
            }
        }
    }
    
    var isBusy: Bool {
        isBuffering || activeOperationCount > 0
    }
    var volume: Percentage {
        get {
            systemVolume
        }
        set {
            MPVolumeView.setVolume(Float(newValue))
        }
    }
    var playbackRate: Percentage {
        get {
            .init(audioPlayer.defaultRate)
        }
        set {
            audioPlayer.defaultRate = Float(newValue)
            
            if audioPlayer.rate > 0 {
                audioPlayer.rate = audioPlayer.defaultRate
            }
            
            Task {
                await AudioPlayer.shared.playbackRateDidChange(endpointID: id, playbackRate: newValue)
            }
        }
    }
    
    var pendingTimeSpendListening: TimeInterval {
        get async {
            await playbackReporter.accumulatedServerReportedTimeListening
        }
    }
}

extension LocalAudioEndpoint {
    func queue(_ items: [AudioPlayerItem]) async throws {
        for item in items {
            queue.append(item)
        }
        
        await AudioPlayer.shared.queueDidChange(endpointID: id, queue: queue.map(\.itemID))
    }
    
    func stop() async {
        await playbackReporter.finalize(currentTime: currentTime)
        await PersistenceManager.shared.download.removeBlock(from: currentItemID)
        
        audioPlayer.removeAllItems()
        
        cancelUpdateBufferingCheck()
        sleepTimeoutTimer?.invalidate()
        
        await AudioPlayer.shared.didStopPlaying(endpointID: id, itemID: currentItemID)
    }
    
    func play() async {
        audioPlayer.play()
        isPlaying = true
        
        if let sleepLastPause, let sleepTimer, case .interval(let until, let extend) = sleepTimer {
            self.sleepTimer = .interval(until.advanced(by: sleepLastPause.distance(to: .now)), extend)
            self.sleepLastPause = nil
        }
        
        updateSleepTimerSchedule()
        
        await playbackReporter.didChangePlayState(isPlaying: true)
        await AudioPlayer.shared.playStateDidChange(endpointID: id, isPlaying: true, updateSessionActivation: true)
    }
    
    func pause() async {
        await pause(updateSessionActivation: false)
    }
    
    func seek(to: TimeInterval, insideChapter: Bool) async throws {
        let time: TimeInterval
        
        if insideChapter, let activeChapterIndex {
            time = to + chapters[activeChapterIndex].startOffset
        } else {
            time = to
        }
        
        logger.info("Seeking to \(time)")
        
        guard time >= 0 else {
            try await seek(to: 0, insideChapter: insideChapter)
            return
        }
        
        if let duration, time >= duration {
            await didPlayToEnd(finishedCurrentItem: true)
            return
        }
        
        activeOperationCount += 1
        audioPlayer.pause()
        
        let index = try! audioTrackIndex(at: time)
        
        if index != activeAudioTrackIndex {
            let playerItems = audioPlayer.items()
            
            if playerItems.count > index && index > activeAudioTrackIndex {
                for surplusIndex in 1..<(index - activeAudioTrackIndex) {
                    audioPlayer.remove(playerItems[surplusIndex])
                }
                
                audioPlayer.advanceToNextItem()
            } else {
                try await repopulateAudioPlayerQueue(start: index)
            }
            
            activeAudioTrackIndex = index
        }
        
        await audioPlayer.seek(to: CMTime(seconds: time - audioTracks[index].offset, preferredTimescale: 1000))
        
        currentTime = time
        await updateChapterIndex()
        
        if isPlaying {
            audioPlayer.play()
        }
        
        activeOperationCount -= 1
    }
    
    func setVolume(_ volume: Percentage) {
        self.volume = volume
    }
    func setPlaybackRate(_ rate: Percentage) {
        playbackRate = rate
        updatePeriodicObserver()
    }
    
    func setSleepTimer(_ configuration: SleepTimerConfiguration?) {
        sleepTimer = configuration
    }
    
    func skip(queueIndex index: Int) async {
        queue.removeSubrange(0..<index)
        
        await queueDidChange()
        await didPlayToEnd(finishedCurrentItem: false)
    }
    func skip(upNextQueueIndex index: Int) async {
        queue.removeAll()
        upNextQueue.removeSubrange(0..<index)
        
        await queueDidChange()
        await nextUpQueueDidChange()
        
        await didPlayToEnd(finishedCurrentItem: false)
    }
    
    func move(queueIndex: IndexSet, to: Int) async {
        queue.move(fromOffsets: queueIndex, toOffset: to)
    }
    
    func remove(queueIndex index: Int) async {
        queue.remove(at: index)
        await queueDidChange()
    }
    func remove(upNextQueueIndex index: Int) async {
        upNextQueue.remove(at: index)
        await nextUpQueueDidChange()
    }
    
    func clearQueue() async {
        queue.removeAll()
        await queueDidChange()
    }
    func clearUpNextQueue() async {
        upNextQueue.removeAll()
        await nextUpQueueDidChange()
        
        allowUpNextQueueGeneration = false
    }
    
    func queueDidChange() async {
        await AudioPlayer.shared.queueDidChange(endpointID: id, queue: queue.map(\.itemID))
    }
    func nextUpQueueDidChange() async {
        await AudioPlayer.shared.upNextQueueDidChange(endpointID: id, upNextQueue: upNextQueue.map(\.itemID))
    }
}

private extension LocalAudioEndpoint {
    func pause(updateSessionActivation: Bool) async {
        audioPlayer.pause()
        isPlaying = false
        
        sleepLastPause = .now
        updateSleepTimerSchedule()
        
        await playbackReporter.didChangePlayState(isPlaying: false)
        await AudioPlayer.shared.playStateDidChange(endpointID: id, isPlaying: false, updateSessionActivation: updateSessionActivation)
    }
    
    func start() async throws {
        let downloadStatus = await PersistenceManager.shared.download.status(of: currentItemID)
        
        guard downloadStatus != .downloading else {
            throw AudioPlayerError.downloading
        }
                
        let task = UIApplication.shared.beginBackgroundTask(withName: "LocalAudioEndpoint::start")
        
        audioTracks = []
        activeAudioTrackIndex = -1
        
        chapters = []
        activeChapterIndex = nil
        
        isPlaying = false
        
        activeOperationCount += 1
        isBuffering = true
        
        duration = nil
        currentTime = nil
        
        chapterDuration = nil
        chapterCurrentTime = nil
        
        var audioTracks = [PlayableItem.AudioTrack]()
        var chapters = [Chapter]()
        
        let startTime: TimeInterval
        let sessionID: String?
        
        do {
            if OfflineMode.shared.isEnabled {
                throw AudioPlayerError.offline
            }
            
            // Attempt to start a playback session
            
            (audioTracks, chapters, startTime, sessionID) = try await ABSClient[currentItemID.connectionID].startPlaybackSession(itemID: currentItemID)
            
            Defaults[.openPlaybackSessions].append(OpenPlaybackSessionPayload(sessionID: sessionID!, itemID: currentItemID))
        } catch {
            // Fall back to resolving and reporting locally
            
            let entity = await PersistenceManager.shared.progress[currentItemID]
            
            if entity.isFinished {
                startTime = 0
            } else {
                var currentTime = entity.currentTime
                
                // 10 minutes
                if Defaults[.enableSmartRewind] && entity.lastUpdate.distance(to: Date()) >= 10 * 60 {
                    currentTime -= 30
                }
                
                startTime = max(currentTime, 0)
            }
            
            sessionID = nil
        }
        
        do {
            if downloadStatus == .completed {
                audioTracks = try await PersistenceManager.shared.download.audioTracks(for: currentItemID)
                chapters = await PersistenceManager.shared.download.chapters(itemID: currentItemID)
            }
            
            guard !audioTracks.isEmpty else {
                throw AudioPlayerError.loadFailed
            }
        } catch {
            activeOperationCount -= 1
            logger.error("Failed to load audio tracks: \(error)")
            
            UIApplication.shared.endBackgroundTask(task)
            
            throw error
        }
        
        if currentItemID.type == .episode, let episode = try? await currentItemID.resolved as? Episode, let extracted = episode.chapters {
            chapters = extracted
        }
        
        await PersistenceManager.shared.download.addBlock(to: currentItemID)
        
        self.audioTracks = audioTracks.sorted()
        self.chapters = chapters.sorted()
        
        playbackReporter = .init(itemID: currentItemID, startTime: startTime, sessionID: sessionID)
        
        do {
            try await seek(to: startTime, insideChapter: false)
        } catch {
            logger.error("Failed to seek to start time: \(error)")
        }
        
        await AudioPlayer.shared.didStartPlaying(endpointID: id, itemID: currentItemID, chapters: self.chapters, at: startTime)
        
        await updateDuration()
        
        let playbackRate: Percentage
        
        if let itemPlaybackRate = await PersistenceManager.shared.item.playbackRate(for: currentItemID) {
            playbackRate = itemPlaybackRate
        } else if let groupingID = await groupingID, let groupingPlaybackRate = await PersistenceManager.shared.item.playbackRate(for: groupingID) {
            playbackRate = groupingPlaybackRate
        } else {
            playbackRate = Defaults[.defaultPlaybackRate]
        }
        
        self.playbackRate = playbackRate
        
        await play()
        
        if let output = AVAudioSession.sharedInstance().currentRoute.outputs.first {
            route = .init(name: output.portName, port: output.portType)
        }
        
        activeOperationCount -= 1
        
        updateUpNextQueue()
        scheduleConfiguredSleepTimer()
        
        Defaults[.lastPlayedItemID] = currentItemID
        UIApplication.shared.endBackgroundTask(task)
    }
    
    func updateChapterIndex() async {
        if let currentTime {
            let activeChapterIndex = chapterIndex(at: currentTime)
            
            self.activeChapterIndex = activeChapterIndex
            
            if let activeChapterIndex {
                chapterValidUntil = chapters[activeChapterIndex].endOffset
                await AudioPlayer.shared.chapterDidChange(endpointID: id, chapter: chapters[activeChapterIndex])
            } else {
                chapterValidUntil = chapters.first { $0.startOffset > currentTime }?.startOffset
                await AudioPlayer.shared.chapterDidChange(endpointID: id, chapter: nil)
            }
            
            await self.updateDuration()
        } else if !Defaults[.enableChapterTrack] {
            activeChapterIndex = nil
            chapterValidUntil = nil
            
            await AudioPlayer.shared.chapterDidChange(endpointID: id, chapter: nil)
            await self.updateDuration()
        }
        
        await AudioPlayer.shared.chapterIndexDidChange(endpointID: id, chapterIndex: activeChapterIndex, chapterCount: chapters.count)
    }
    
    func audioTrackIndex(at time: TimeInterval) throws -> Int {
        if let index = audioTracks.firstIndex(where: { time >= $0.offset && time < ($0.offset + $0.duration) }) {
            index
        } else {
            throw AudioPlayerError.missingAudioTrack
        }
    }
    func chapterIndex(at time: TimeInterval) -> Int? {
        guard Defaults[.enableChapterTrack] else {
            return nil
        }
        
        return chapters.firstIndex(where: { time >= $0.startOffset && time < $0.endOffset })
    }
    
    func updateDuration() async {
        if let last = audioTracks.last {
            duration = last.offset + last.duration
        }
        
        if let activeChapterIndex {
            chapterDuration = chapters[activeChapterIndex].endOffset - chapters[activeChapterIndex].startOffset
        } else {
            chapterDuration = duration
        }
        
        if let duration {
            await playbackReporter.update(duration: duration)
        }
        
        await AudioPlayer.shared.durationsDidChange(endpointID: id, itemDuration: duration, chapterDuration: chapterDuration)
    }
    
    @MainActor
    func updateBufferingCheckTaskSchedule() {
        if !isBuffering && bufferCheckTimer != nil {
            cancelUpdateBufferingCheck()
        } else if isBuffering && bufferCheckTimer == nil {
            bufferCheckTimer = Timer(timeInterval: 1, repeats: true) { _ in
                Task {
                    await self.checkBufferHealth()
                }
            }
            
            RunLoop.main.add(bufferCheckTimer!, forMode: .common)
        }
    }
    @MainActor
    func cancelUpdateBufferingCheck() {
        bufferCheckTimer?.invalidate()
        bufferCheckTimer = nil
    }
    func checkBufferHealth() async {
        let isBuffering: Bool
        
        if let item = audioPlayer.currentItem {
            isBuffering = !(item.status == .readyToPlay && item.isPlaybackLikelyToKeepUp)
        } else {
            isBuffering = true
        }
        
        if self.isBuffering != isBuffering {
            self.isBuffering = isBuffering
            
            await AudioPlayer.shared.bufferHealthDidChange(endpointID: id, isBuffering: isBuffering)
        }
    }
    
    func sleepChapterDidEnd() async {
        guard let sleepTimer, case .chapters(let amount, let extend) = sleepTimer else {
            return
        }
        
        if amount <= 1 {
            await pause()
            
            self.sleepTimer = nil
            await AudioPlayer.shared.sleepTimerDidExpire(endpointID: id, configuration: sleepTimer)
            
            return
        } else {
            await AudioPlayer.shared.setSleepTimer(.chapters(amount - 1, extend))
        }
    }
    func updateSleepTimerSchedule() {
        guard let sleepTimer, case .interval(let date, _) = sleepTimer else {
            sleepTimeoutTimer?.invalidate()
            return
        }
        
        guard isPlaying else {
            sleepTimeoutTimer?.invalidate()
            return
        }
        
        let distance = Date.now.distance(to: date)
        let waitTime: TimeInterval
        
        if distance <= 10 {
            waitTime = 1
        } else {
            waitTime = distance - 10
        }
        
        logger.info("Scheduling sleep timer for \(waitTime) seconds")
        
        sleepTimeoutTimer = .init(timeInterval: waitTime, repeats: false) { [weak self] _ in
            guard let self else {
                return
            }
            
            Task { @MainActor in
                let distance = Date.now.distance(to: date)
                
                if Defaults[.sleepTimerFadeOut] {
                    if distance < 10 {
                        self.audioPlayer.volume = Float(distance / 10)
                    }
                }
                
                if distance <= 0 {
                    await self.pause()
                    
                    self.sleepTimer = nil
                    self.sleepLastPause = nil
                    
                    self.audioPlayer.volume = self.audioPlayerVolume
                    await AudioPlayer.shared.sleepTimerDidExpire(endpointID: self.id, configuration: sleepTimer)
                }
                
                self.updateSleepTimerSchedule()
            }
        }
        RunLoop.main.add(sleepTimeoutTimer!, forMode: .common)
    }
    
    func repopulateAudioPlayerQueue(start index: Int) async throws {
        audioPlayer.removeAllItems()
        
        let headers = try await ABSClient[currentItemID.connectionID].requestHeaders
        
        // TODO: Provide Identity
        
        for audioTrack in audioTracks[index..<audioTracks.endIndex] {
            let asset = AVURLAsset(url: audioTrack.resource, options: [
                "AVURLAssetHTTPHeaderFieldsKey": headers,
            ])
            let playerItem = AVPlayerItem(asset: asset)
            
            audioPlayer.insert(playerItem, after: nil)
        }
    }
    func updateUpNextQueue(using forced: ResolvedUpNextStrategy? = nil) {
        Task.detached { [weak self] in
            guard let self, await upNextQueue.isEmpty else {
                return
            }
            
            guard Defaults[.generateUpNextQueue] else {
                return
            }
            
            let currentItem = await currentItem
            let currentItemID = await currentItemID
            
            let strategy: ResolvedUpNextStrategy?
            
            do {
                if let forced {
                    strategy = forced
                } else if let resolved = currentItem.origin.resolvedUpNextStrategy {
                    strategy = resolved
                } else if let podcastID = await podcastID {
                    strategy = (await PersistenceManager.shared.item.upNextStrategy(for: podcastID) ?? .default).resolved(podcastID)
                } else if let seriesID = await seriesID {
                    strategy = (await PersistenceManager.shared.item.upNextStrategy(for: seriesID) ?? .default).resolved(seriesID)
                } else {
                    strategy = nil
                }
                
                guard let strategy else {
                    throw AudioPlayerError.invalidItemType
                }
                
                let items = try await strategy.resolve(cutoff: currentItemID).map { AudioPlayerItem(itemID: $0.id, origin: .upNextQueue) }
                
                await MainActor.run {
                    self.upNextStrategy = strategy
                    self.upNextQueue = items
                }
                
                await AudioPlayer.shared.upNextQueueDidChange(endpointID: id, upNextQueue: upNextQueue.map(\.itemID))
                await AudioPlayer.shared.upNextStrategyDidChange(endpointID: id, strategy: strategy)
            } catch {
                logger.error("Failed to update up next queue: \(error)")
            }
        }
    }
    func scheduleConfiguredSleepTimer() {
        Task {
            guard sleepTimer == nil else {
                return
            }
            
            let sleepTimer: SleepTimerConfiguration
            
            if currentItemID.type == .audiobook, let configured = await PersistenceManager.shared.item.sleepTimer(for: currentItemID) {
                sleepTimer = configured
            } else if let groupingID = await groupingID, let configured = await PersistenceManager.shared.item.sleepTimer(for: groupingID) {
                sleepTimer = configured
            } else {
                return
            }
            
            setSleepTimer(sleepTimer)
        }
    }
    
    func didPlayToEnd(finishedCurrentItem: Bool) async {
        await playbackReporter.finalize(currentTime: finishedCurrentItem ? duration : currentTime)
        
        if finishedCurrentItem {
            Defaults[.lastPlayedItemID] = nil
            
            Task.detached {
                await withTaskGroup {
                    $0.addTask { await PersistenceManager.shared.convenienceDownload.pruneFinishedDownloads() }
                }
            }
        }
        
        let nextItem: AudioPlayerItem
        
        if !queue.isEmpty {
            nextItem = queue.removeFirst()
            await AudioPlayer.shared.queueDidChange(endpointID: id, queue: queue.map(\.itemID))
        } else if !upNextQueue.isEmpty {
            nextItem = upNextQueue.removeFirst()
            await AudioPlayer.shared.upNextQueueDidChange(endpointID: id, upNextQueue: upNextQueue.map(\.itemID))
        } else {
            await AudioPlayer.shared.stop(endpointID: id)
            return
        }
        
        audioPlayer.removeAllItems()
        currentItem = nextItem
        
        do {
            try await start()
        } catch {
            await AudioPlayer.shared.stop(endpointID: id)
        }
    }
    
    private func repopulateQueueTrigger(connectionID: ItemIdentifier.ConnectionID?) {
        if let connectionID, currentItemID.connectionID != connectionID {
            return
        }
        
        guard let currentTime else {
            return
        }
        
        Task {
            do {
                try await repopulateAudioPlayerQueue(start: activeAudioTrackIndex)
                try await seek(to: currentTime, insideChapter: false)
            } catch {
                logger.error("Failed to repopulate queue after access token expired. Stopping playback: \(error)")
                await AudioPlayer.shared.stop(endpointID: id)
            }
        }
    }
    func setupObservers() {
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.repopulateQueueTrigger(connectionID: nil)
        }
        RFNotification[.accessTokenExpired].subscribe { [weak self] connectionID in
            self?.repopulateQueueTrigger(connectionID: connectionID)
        }
        
        RFNotification[.collectionChanged].subscribe { [weak self] collectionID in
            guard self?.upNextStrategy?.itemID == collectionID else {
                return
            }
            
            self?.upNextQueue.removeAll()
            self?.updateUpNextQueue(using: .collection(collectionID))
        }
        RFNotification[.progressEntityUpdated].subscribe { [weak self] connectionID, primaryID, groupingID, entity in
            guard entity?.isFinished == true else {
                return
            }
            
            self?.queue.removeAll { $0.itemID.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }
            self?.upNextQueue.removeAll { $0.itemID.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }
            
            Task {
                guard let id = self?.id, let queue = self?.queue, let upNextQueue = self?.upNextQueue else {
                    return
                }
                
                await AudioPlayer.shared.queueDidChange(endpointID: id, queue: queue.map(\.itemID))
                await AudioPlayer.shared.upNextQueueDidChange(endpointID: id, upNextQueue: upNextQueue.map(\.itemID))
            }
        }
        
        volumeSubscription = AVAudioSession.sharedInstance().publisher(for: \.outputVolume).sink { [weak self] volume in
            self?.systemVolume = .init(volume)
            
            guard let id = self?.id, let systemVolume = self?.systemVolume else {
                return
            }
            
            Task {
                await AudioPlayer.shared.volumeDidChange(endpointID: id, volume: systemVolume)
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance(), queue: nil) { [weak self] notification in
            guard let userInfo = notification.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
            
            Task {
                switch type {
                case .began:
                    await self?.pause(updateSessionActivation: true)
                case .ended:
                    guard let optionsValue else {
                        return
                    }
                    
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    
                    if options.contains(.shouldResume) {
                        await self?.play()
                    }
                default:
                    break
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                if let output = AVAudioSession.sharedInstance().currentRoute.outputs.first {
                    self?.route = .init(name: output.portName, port: output.portType)
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else {
                return
            }
            
            MainActor.assumeIsolated {
                if activeAudioTrackIndex >= audioTracks.index(before: audioTracks.endIndex) {
                    Task {
                        await didPlayToEnd(finishedCurrentItem: true)
                    }
                } else {
                    activeAudioTrackIndex += 1
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            Task {
                guard let self else {
                    return
                }
                
                await AudioPlayer.shared.stop(endpointID: self.id)
            }
        }
        
        updatePeriodicObserver()
    }
    func updatePeriodicObserver() {
        if let audioPlayerSubscription {
            audioPlayer.removeTimeObserver(audioPlayerSubscription)
        }
        
        audioPlayerSubscription = audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1 * (1 / playbackRate), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] _ in
            guard let self else {
                return
            }
            
            MainActor.assumeIsolated {
                let _ = Task {
                    // MARK: Buffering
                    
                    await checkBufferHealth()
                    
                    // MARK: Current time
                    
                    if activeAudioTrackIndex >= 0 {
                        let audioTrack = audioTracks[activeAudioTrackIndex]
                        let seconds = audioPlayer.currentTime().seconds
                        
                        currentTime = audioTrack.offset + seconds
                    }
                    
                    // MARK: Chapter
                    
                    if !chapters.isEmpty, let currentTime = currentTime, let chapterValidUntil = chapterValidUntil, chapterValidUntil < currentTime {
                        await updateChapterIndex()
                    }
                    
                    // MARK: Chapter current time
                    
                    if let currentTime = currentTime, let activeChapterIndex = activeChapterIndex {
                        let chapter = chapters[activeChapterIndex]
                        chapterCurrentTime = currentTime - chapter.startOffset
                    } else {
                        chapterCurrentTime = currentTime
                    }
                    
                    if let currentTime = currentTime {
                        await playbackReporter.update(currentTime: currentTime)
                    }
                    
                    await AudioPlayer.shared.currentTimesDidChange(endpointID: id, itemCurrentTime: currentTime, chapterCurrentTime: chapterCurrentTime)
                }
            }
        }
    }
}

private extension AudioPlayerItem.PlaybackOrigin {
    var resolvedUpNextStrategy: ResolvedUpNextStrategy? {
        switch self {
            case .series(let seriesID):
                    .series(seriesID)
            case .podcast(let podcastID):
                    .podcast(podcastID)
            case .collection(let collectionID):
                    .collection(collectionID)
            default:
                nil
        }
    }
}
private extension ConfigureableUpNextStrategy {
    func resolved(_ itemID: ItemIdentifier) -> ResolvedUpNextStrategy {
        switch self {
            case .default:
                switch itemID.type {
                    case .series:
                        return .series(itemID)
                    case .podcast:
                        return .podcast(itemID)
                    default:
                        fatalError("Not resolved: \(self)")
                }
            case .listenNow:
                return .listenNow
            case .disabled:
                return .none
        }
    }
}
