//
//  PauseIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import AppIntents
import Defaults

public struct PauseIntent: AppIntent, AudioPlaybackIntent {
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public static let title: LocalizedStringResource = "intent.pause"
    public static let description = IntentDescription("intent.pause.description")
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            let current = Defaults[.lastListened]
            Defaults[.lastListened] = .init(item: current?.item, isDownloaded: current?.isDownloaded ?? false, isPlaying: nil)
            
            throw IntentError.noPlaybackItem
        }
        
        await audioPlayer.setPlaying(false)
        
        return .result()
    }
}
