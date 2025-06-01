//
//  IntentAudioPlayer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

public final class IntentAudioPlayer: Sendable {
    let resolveIsPlaying: @Sendable () async -> Bool?
    let _setPlaying: @Sendable (Bool) async -> Void
    let _start: @Sendable (ItemIdentifier, Bool) async throws -> Void
    
    public init(resolveIsPlaying: @Sendable @escaping () async -> Bool?, setPlaying: @Sendable @escaping (Bool) async -> Void, start: @Sendable @escaping (ItemIdentifier, Bool) async throws -> Void) {
        self.resolveIsPlaying = resolveIsPlaying
        self._setPlaying = setPlaying
        self._start = start
    }
    
    var isPlaying: Bool? {
        get async {
            await resolveIsPlaying()
        }
    }
    func setPlaying(_ playing: Bool) async {
        await _setPlaying(playing)
    }
    func start(_ item: ItemIdentifier, _ withoutPlaybackSession: Bool) async throws {
        try await _start(item, withoutPlaybackSession)
    }
}
