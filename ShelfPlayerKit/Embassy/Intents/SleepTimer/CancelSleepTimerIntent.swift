//
//  SetSleepTimerIntent 3.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.06.25.
//

import Foundation
import AppIntents

public struct CancelSleepTimerIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.cancelSleepTimer"
    public static let description = IntentDescription("intent.cancelSleepTimer.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }
        
        await audioPlayer.setSleepTimer(nil)
        
        return .result()
    }
}
