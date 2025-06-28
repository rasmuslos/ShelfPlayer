//
//  SetSleepTimerIntent 2.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.06.25.
//

import Foundation
import AppIntents

public struct ExtendSleepTimerIntent: AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.extendSleepTimer"
    public static let description = IntentDescription("intent.extendSleepTimer.description")
    
    @AppDependency private var audioPlayer: IntentAudioPlayer
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        guard await audioPlayer.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }
        
        await audioPlayer.extendSleepTimer()
        
        return .result()
    }
}
