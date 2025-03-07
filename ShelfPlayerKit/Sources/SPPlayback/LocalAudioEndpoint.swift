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
import Defaults
import SPFoundation
import SPPersistence

@MainActor
final class LocalAudioEndpoint: AudioEndpoint {
    nonisolated let id = UUID()
    
    private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "LocalAudioEndpoint")
    
    private let audioPlayer: AVQueuePlayer
    
    private var playbackReporter: PlaybackReporter!
    
    private(set) var currentItemID: ItemIdentifier
    
    private(set) var queue: [QueueItem]
    private(set) var upNextQueue: [QueueItem]
    
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
    
    private var allowUpNextGeneration: Bool
    private var chapterValidUntil: TimeInterval?
    
    private var volumeSubscription: AnyCancellable?
    private var bufferCheckTimer: Timer?
    
    private var sleepLastPause: Date?
    private var sleepTimeoutTimer: Timer?
    
    let audioPlayerVolume: Float = 1
    
    init(itemID: ItemIdentifier, withoutListeningSession: Bool) async throws {
        logger.info("Starting up local audio endpoint with item ID \(itemID) (without listening session: \(withoutListeningSession))")
        
        playbackReporter = nil
        audioPlayer = .init()
        
        currentItemID = itemID
        
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
        
        allowUpNextGeneration = true
        
        setupObservers()
        
        try await start(withoutListeningSession: withoutListeningSession)
    }
    deinit {
        // bufferCheckTimer?.invalidate()
        logger.info("Deinitializing local audio endpoint: \(self.id)")
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
}

extension LocalAudioEndpoint {
    func queue(_ items: [QueueItem]) async throws {
        for item in items {
            queue.append(item)
        }
        
        await AudioPlayer.shared.queueDidChange(endpointID: id, queue: queue.map(\.itemID))
    }
    
    func stop() async {
        await playbackReporter.finalize()
        audioPlayer.removeAllItems()
        
        cancelUpdateBufferingCheck()
        sleepTimeoutTimer?.invalidate()
        
        await AudioPlayer.shared.didStopPlaying(endpointID: id, itemID: currentItemID)
    }
    
    func play() async {
        audioPlayer.play()
        isPlaying = true
        
        if let sleepLastPause, let sleepTimer, case .interval(let until) = sleepTimer {
            self.sleepTimer = .interval(until.advanced(by: sleepLastPause.distance(to: .now)))
            self.sleepLastPause = nil
        }
        
        updateSleepTimerSchedule()
        
        await playbackReporter.didChangePlayState(isPlaying: true)
        await AudioPlayer.shared.playStateDidChange(endpointID: id, isPlaying: true)
    }
    
    func pause() async {
        audioPlayer.pause()
        isPlaying = false
        
        sleepLastPause = .now
        updateSleepTimerSchedule()
        
        await playbackReporter.didChangePlayState(isPlaying: false)
        await AudioPlayer.shared.playStateDidChange(endpointID: id, isPlaying: false)
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
            await playbackReporter.update(currentTime: duration)
            await playbackReporter.finalize()
            
            await didPlayToEnd()
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
                audioPlayer.removeAllItems()
                
                let headers = Dictionary(uniqueKeysWithValues: try await ABSClient[currentItemID.connectionID].headers.map { ($0.key, $0.value) })
                
                for audioTrack in audioTracks[index..<audioTracks.endIndex] {
                    let asset = AVURLAsset(url: audioTrack.resource, options: [
                        "AVURLAssetHTTPHeaderFieldsKey": headers,
                    ])
                    let playerItem = AVPlayerItem(asset: asset)
                    
                    audioPlayer.insert(playerItem, after: nil)
                }
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
    }
    
    func setSleepTimer(_ configuration: SleepTimerConfiguration?) {
        sleepTimer = configuration
    }
    
    func skip(queueIndex index: Int) async {
        queue.removeSubrange(0..<index)
        await queueDidChange()
        
        await didPlayToEnd()
    }
    func skip(upNextQueueIndex index: Int) async {
        queue.removeAll()
        upNextQueue.removeSubrange(0..<index)
        
        await queueDidChange()
        await nextUpQueueDidChange()
        
        await didPlayToEnd()
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
        
        allowUpNextGeneration = false
    }
    
    func queueDidChange() async {
        await AudioPlayer.shared.queueDidChange(endpointID: id, queue: queue.map(\.itemID))
    }
    func nextUpQueueDidChange() async {
        await AudioPlayer.shared.upNextQueueDidChange(endpointID: id, upNextQueue: upNextQueue.map(\.itemID))
    }
}

private extension LocalAudioEndpoint {
    func start(withoutListeningSession: Bool) async throws {
        let downloadStatus = await PersistenceManager.shared.download.status(of: currentItemID)
        
        guard downloadStatus != .downloading else {
            throw AudioPlayerError.downloading
        }
        
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
            if withoutListeningSession {
                throw AudioPlayerError.offline
            }
            
            // Attempt to start a playback session
            
            (audioTracks, chapters, startTime, sessionID) = try await ABSClient[currentItemID.connectionID].startPlaybackSession(itemID: currentItemID)
        } catch {
            // Fall back to resolving and reporting locally
            
            let entity = await PersistenceManager.shared.progress[currentItemID]
            
            if entity.isFinished {
                startTime = 0
            } else {
                var currentTime = entity.currentTime
                
                if Defaults[.enableSmartRewind] && entity.lastUpdate.timeIntervalSince(Date()) >= 10 * 60 {
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
            
            throw error
        }
        
        self.audioTracks = audioTracks.sorted()
        self.chapters = chapters.sorted()
        
        playbackReporter = .init(itemID: currentItemID, sessionID: sessionID)
        
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
        } else if let podcastPlaybackRate = await PersistenceManager.shared.podcasts.playbackRate(for: currentItemID) {
            playbackRate = podcastPlaybackRate
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
    }
    
    func updateChapterIndex() async {
        if let currentTime {
            let activeChapterIndex = chapterIndex(at: currentTime)
            
            self.activeChapterIndex = activeChapterIndex
            
            if let activeChapterIndex {
                chapterValidUntil = chapters[activeChapterIndex].endOffset
                await AudioPlayer.shared.chapterDidChange(endpointID: id, chapter: chapters[activeChapterIndex])
            } else {
                chapterValidUntil = nil
                await AudioPlayer.shared.chapterDidChange(endpointID: id, chapter: nil)
            }
            
            await self.updateDuration()
        } else if !Defaults[.enableChapterTrack] {
            activeChapterIndex = nil
            chapterValidUntil = nil
            
            await AudioPlayer.shared.chapterDidChange(endpointID: id, chapter: nil)
            await self.updateDuration()
        }
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
        guard let sleepTimer, case .chapters(let amount) = sleepTimer else {
            return
        }
        
        guard amount > 1 else {
            await pause()
            
            self.sleepTimer = nil
            await AudioPlayer.shared.sleepTimerDidExpire(endpointID: id, configuration: sleepTimer)
            
            return
        }
    }
    func updateSleepTimerSchedule() {
        guard let sleepTimer, case .interval(let date) = sleepTimer else {
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
    
    func updateUpNextQueue() {
        Task.detached { [weak self] in
            guard let self else {
                return
            }
            
            guard await allowUpNextGeneration else {
                await clearUpNextQueue()
                return
            }
            
            guard await upNextQueue.isEmpty else {
                return
            }
            
            let currentItemID = await currentItemID
            
            do {
                if currentItemID.type == .episode {
                    let podcastID = ItemIdentifier(primaryID: currentItemID.groupingID!, groupingID: nil, libraryID: currentItemID.libraryID, connectionID: currentItemID.connectionID, type: .podcast)
                    let (_, episodes) = try await podcastID.resolvedComplex
                    let sorted = await Podcast.filterSort(episodes, seasonFilter: Defaults[.episodesSeasonFilter(podcastID)], filter: Defaults[.episodesFilter(podcastID)], search: nil, sortOrder: Defaults[.episodesSortOrder(podcastID)], ascending: Defaults[.episodesAscending(podcastID)]).filter { $0.id != currentItemID }
                    
                    // TODO: better maybe?
                    await MainActor.run {
                        upNextQueue = sorted.map { .init(itemID: $0.id, startWithoutListeningSession: false) }
                    }
                } else {
                    // TODO: series
                    return
                }
                
                await AudioPlayer.shared.upNextQueueDidChange(endpointID: id, upNextQueue: upNextQueue.map(\.itemID))
            } catch {
                logger.error("Failed to update up next queue: \(error)")
            }
        }
    }
    func didPlayToEnd() async {
        let nextItemID: ItemIdentifier
        let startWithoutListeningSession: Bool
        
        if !queue.isEmpty {
            let queueItem = queue.removeFirst()
            
            nextItemID = queueItem.itemID
            startWithoutListeningSession = queueItem.startWithoutListeningSession
        } else if !upNextQueue.isEmpty {
            let queueItem = upNextQueue.removeFirst()
            
            nextItemID = queueItem.itemID
            startWithoutListeningSession = queueItem.startWithoutListeningSession
        } else {
            await AudioPlayer.shared.stop(endpointID: id)
            return
        }
        
        audioPlayer.removeAllItems()
        
        currentItemID = nextItemID
        
        do {
            try await start(withoutListeningSession: startWithoutListeningSession)
        } catch {
            await AudioPlayer.shared.stop(endpointID: id)
        }
    }
    
    func setupObservers() {
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
                    await self?.pause()
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
                        await didPlayToEnd()
                    }
                } else {
                    activeAudioTrackIndex += 1
                }
            }
        }
        
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] _ in
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
