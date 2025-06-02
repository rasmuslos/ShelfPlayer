//
//  PlayIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import AppIntents
import WidgetKit
import Defaults

public struct PlayIntent: AppIntent, AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.play"
    public static let description = IntentDescription("intent.play.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            Embassy.unsetWidgetIsPlaying()
            throw IntentError.noPlaybackItem
        }
        
        await audioPlayer.setPlaying(true)
        
        return .result()
    }
}
