//
//  IntentAudioPlayer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Foundation

public final class IntentAudioPlayer: Sendable {
    let resolveIsPlaying: @Sendable () async -> Bool?
    let resolveCurrentItemID: @Sendable () async -> ItemIdentifier?
    
    let _setPlaying: @Sendable (Bool) async -> Void
    let _start: @Sendable (ItemIdentifier) async throws -> Void
    let _startGrouping: @Sendable (ItemIdentifier) async throws -> ItemIdentifier
    
    let _createBookmark: @Sendable (String?) async throws -> Void
    let _skip: @Sendable (TimeInterval?, Bool) async throws -> Void
    
    let _setSleepTimer: @Sendable (SleepTimerConfiguration?) async -> Void
    let _extendSleepTimer: @Sendable () async -> Void
    
    let _setPlaybackRate: @Sendable (Percentage) async -> Void
    
    public init(resolveIsPlaying: @Sendable @escaping () async -> Bool?,
                resolveCurrentItemID: @Sendable @escaping () async -> ItemIdentifier?,
                setPlaying: @Sendable @escaping (Bool) async -> Void,
                start: @Sendable @escaping (ItemIdentifier) async throws -> Void,
                startGrouping: @Sendable @escaping (ItemIdentifier) async throws -> ItemIdentifier,
                createBookmark: @Sendable @escaping (String?) async throws -> Void,
                skip: @Sendable @escaping (TimeInterval?, Bool) async throws -> Void,
                setSleepTimer: @Sendable @escaping (SleepTimerConfiguration?) async -> Void,
                extendSleepTimer: @Sendable @escaping () async -> Void,
                setPlaybackRate: @Sendable @escaping (Percentage) async -> Void
    ) {
        self.resolveIsPlaying = resolveIsPlaying
        self.resolveCurrentItemID = resolveCurrentItemID
        
        _setPlaying = setPlaying
        _start = start
        _startGrouping = startGrouping
        _createBookmark = createBookmark
        _skip = skip
        _setSleepTimer = setSleepTimer
        _extendSleepTimer = extendSleepTimer
        _setPlaybackRate = setPlaybackRate
    }
    
    var isPlaying: Bool? {
        get async {
            await resolveIsPlaying()
        }
    }
    var currentItemID: ItemIdentifier? {
        get async {
            await resolveCurrentItemID()
        }
    }
    
    func setPlaying(_ playing: Bool) async {
        await _setPlaying(playing)
    }
    func start(_ item: ItemIdentifier) async throws {
        try await _start(item)
    }
    func startGrouping(_ item: ItemIdentifier) async throws -> ItemIdentifier {
        try await _startGrouping(item)
    }
    
    func createBookmark(_ note: String?) async throws {
        try await _createBookmark(note)
    }
    
    func skip(_ interval: TimeInterval?, forwards: Bool) async throws {
        try await _skip(interval, forwards)
    }
    
    func setSleepTimer(_ configuration: SleepTimerConfiguration?) async {
        await _setSleepTimer(configuration)
    }
    func extendSleepTimer() async {
        await _extendSleepTimer()
    }
    
    func setPlaybackRate(_ rate: Percentage) async {
        await _setPlaybackRate(rate)
    }
}
