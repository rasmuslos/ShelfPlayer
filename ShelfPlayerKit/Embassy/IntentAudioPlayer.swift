//
//  IntentAudioPlayer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

public final class IntentAudioPlayer: Sendable {
    let resolveIsPlaying: @Sendable () async -> Bool?
    let resolveCurrentItemID: @Sendable () async -> ItemIdentifier?
    
    let _setPlaying: @Sendable (Bool) async -> Void
    let _start: @Sendable (ItemIdentifier, Bool) async throws -> Void
    let _startGrouping: @Sendable (ItemIdentifier, Bool) async throws -> ItemIdentifier
    
    public init(resolveIsPlaying: @Sendable @escaping () async -> Bool?, resolveCurrentItemID: @Sendable @escaping () async -> ItemIdentifier?, setPlaying: @Sendable @escaping (Bool) async -> Void, start: @Sendable @escaping (ItemIdentifier, Bool) async throws -> Void, startGrouping: @Sendable @escaping (ItemIdentifier, Bool) async throws -> ItemIdentifier) {
        self.resolveIsPlaying = resolveIsPlaying
        self.resolveCurrentItemID = resolveCurrentItemID
        self._setPlaying = setPlaying
        self._start = start
        self._startGrouping = startGrouping
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
    func start(_ item: ItemIdentifier, _ withoutPlaybackSession: Bool) async throws {
        try await _start(item, withoutPlaybackSession)
    }
    func startGrouping(_ item: ItemIdentifier, _ withoutPlaybackSession: Bool) async throws -> ItemIdentifier {
        try await _startGrouping(item, withoutPlaybackSession)
    }
}
