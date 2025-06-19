//
//  PlayIntent 2.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.06.25.
//

import Foundation
import AppIntents

public struct CreateBookmarkIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.createBookmark"
    public static let description = IntentDescription("intent.createBookmark.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    @Parameter(title: "intent.createBookmark.note")
    public var note: String?
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }
        
        try await audioPlayer.createBookmark(note)
        
        return .result()
    }
}
