//
//  AudioPlayer.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation
import Defaults
import RFNotifications
import SPFoundation

public final actor AudioPlayer: Sendable {
    var current: (any AudioEndpoint)?
    
    public static let shared = AudioPlayer()
}

public extension AudioPlayer {
    var currentItemID: ItemIdentifier? {
        current?.currentItemID
    }
    var queue: [QueueItem] {
        get async {
            await current?.queue.elements ?? []
        }
    }
    
    var isBusy: Bool {
        current?.isBusy ?? true
    }
    var isPlaying: Bool {
        current?.isPlaying ?? false
    }
    
    var volume: Percentage {
        current?.volume ?? 0
    }
    
    var duration: TimeInterval? {
        current?.duration
    }
    var currentTime: TimeInterval? {
        current?.currentTime
    }
    
    var chapterDuration: TimeInterval? {
        current?.chapterDuration
    }
    var chapterCurrentTime: TimeInterval? {
        current?.chapterCurrentTime
    }
    
    func start(_ itemID: ItemIdentifier, withoutListeningSession: Bool = false) async throws {
        do {
            current = try await LocalAudioEndpoint(itemID: itemID, withoutListeningSession: withoutListeningSession)
        } catch {
            stop()
            throw error
        }
    }
    func queue(_ items: [QueueItem]) async throws {
        if let current {
            try await current.queue(items)
            return
        }
        
        guard !items.isEmpty else {
            return
        }
        
        var items = items
        let item = items.removeFirst()
        
        try await start(item.itemID, withoutListeningSession: item.startWithoutListeningSession)
        try await current!.queue(items)
    }
    func stop() {
        current?.stop()
        current = nil
    }
    
    func play() async {
        await current?.play()
    }
    func pause() async {
        await current?.pause()
    }
    
    func seek(to time: TimeInterval) async throws {
        if let current {
            try await current.seek(to: time)
        }
    }
    func skip(forwards: Bool) async throws {
        guard let currentTime else {
            throw AudioPlayerError.invalidTime
        }
        
        let amount: TimeInterval
        
        if forwards {
            amount = .init(Defaults[.skipForwardsInterval])
        } else {
            amount = -.init(Defaults[.skipBackwardsInterval])
        }
        
        try await seek(to: currentTime + amount)
        
        RFNotification[.skipped].send(forwards)
    }
}
