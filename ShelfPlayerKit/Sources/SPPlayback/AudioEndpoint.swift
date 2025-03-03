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
    
    var currentItemID: ItemIdentifier { get }
    
    var queue: ActorArray<QueueItem> { get }
    var upNextQueue: ActorArray<QueueItem> { get }
    
    var chapters: [Chapter] { get }
    
    var isBusy: Bool { get }
    var isPlaying: Bool { get }
    
    var volume: Percentage { get set }
    var playbackRate: Percentage { get set }
    
    var duration: TimeInterval? { get }
    var currentTime: TimeInterval? { get }
    
    var chapterDuration: TimeInterval? { get }
    var chapterCurrentTime: TimeInterval? { get }
    
    var route: AudioRoute? { get }
    
    func queue(_ items: [QueueItem]) async throws
    func stop() async

    func play() async
    func pause() async
    
    func seek(to time: TimeInterval, insideChapter: Bool) async throws
    
    func clearUpNextQueue() async
}
