//
//  PlayAudiobookIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 03.06.25.
//

import Foundation
import AppIntents

@AppIntent(schema: .books.playAudiobook)
public struct StartAudiobookIntent: AudioPlaybackIntent {
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public init() {}
    public init(audiobook: Audiobook) async {
        self.target = await .init(audiobook: audiobook)
    }
    
    @Parameter(optionsProvider: AudiobookEntityOptionsProvider())
    public var target: AudiobookEntity
    
    public func perform() async throws -> some IntentResult {
        try await audioPlayer.start(target.id, false)
        return .result()
    }
}
