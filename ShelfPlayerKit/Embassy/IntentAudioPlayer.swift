//
//  IntentAudioPlayer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

public final class IntentAudioPlayer: Sendable {
    let resolveIsPlaying: @Sendable () async -> Bool?
    let _setPlaying: @Sendable (Bool) async -> Void
    
    public init(resolveIsPlaying: @Sendable @escaping () async -> Bool?, setPlaying: @Sendable @escaping (Bool) async -> Void) {
        self.resolveIsPlaying = resolveIsPlaying
        self._setPlaying = setPlaying
    }
    
    var isPlaying: Bool? {
        get async {
            await resolveIsPlaying()
        }
    }
    func setPlaying(_ playing: Bool) async {
        await _setPlaying(playing)
    }
}
