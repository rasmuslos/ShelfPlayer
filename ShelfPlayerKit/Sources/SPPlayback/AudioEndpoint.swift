//
//  AudioEndpoint.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation
import SPFoundation

protocol AudioEndpoint: Identifiable, Sendable {
    var id: UUID { get }
    
    init(itemID: ItemIdentifier, withoutListeningSession: Bool) async throws
    
    var currentItemID: ItemIdentifier { get async }
    
    var queue: ActorArray<QueueItem> { get async }
    var upNextQueue: ActorArray<QueueItem> { get async }
    
    var chapters: [Chapter] { get async }
    
    var isBusy: Bool { get async }
    var isPlaying: Bool { get async }
    
    var volume: Percentage { get async }
    var playbackRate: Percentage { get async }
    
    var duration: TimeInterval? { get async }
    var currentTime: TimeInterval? { get async }
    
    var chapterDuration: TimeInterval? { get async }
    var chapterCurrentTime: TimeInterval? { get async }
    
    var route: AudioRoute? { get async }
    var sleepTimer: SleepTimerConfiguration? { get async }
    
    func queue(_ items: [QueueItem]) async throws
    func stop() async

    func play() async
    func pause() async
    
    func seek(to time: TimeInterval, insideChapter: Bool) async throws
    
    func setVolume(_ volume: Percentage) async
    func setPlaybackRate(_ rate: Percentage) async
    
    func setSleepTimer(_ configuration: SleepTimerConfiguration?) async
    
    func skip(queueIndex index: Int) async
    func skip(upNextQueueIndex index: Int) async
    
    func remove(queueIndex index: Int) async
    func remove(upNextQueueIndex index: Int) async
    
    func clearQueue() async
    func clearUpNextQueue() async
}
