//
//  PlayIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import AppIntents
import ShelfPlayerKit

#if canImport(SPPlayback)
import SPPlayback
#endif

struct PlayIntent: AppIntent, AudioPlaybackIntent {
    static let title: LocalizedStringResource = "intent.play"
    static let description = IntentDescription("intent.play.description")
    
    func perform() async throws -> some IntentResult {
        #if canImport(SPPlayback)
        guard await AudioPlayer.shared.currentItemID != nil else {
            throw IntentError.noPlaybackItem
        }
        
        await AudioPlayer.shared.play()
        #else
        throw IntentError.wrongExecutionContext
        #endif
        
        return .result()
    }
}
