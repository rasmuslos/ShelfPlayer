//
//  PlayAudiobookIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 03.06.25.
//

import Foundation
import AppIntents

@AssistantIntent(schema: .books.playAudiobook)
public struct PlayAudiobookIntent: AudioPlaybackIntent {
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public init() {}
    public init(item: Item) async {
        self.target = await .init(item: item)
    }
    
    @Parameter
    public var target: ItemEntity
    
    public func perform() async throws -> some IntentResult {
        try await audioPlayer.start(target.id, false)
        return .result()
    }
}
