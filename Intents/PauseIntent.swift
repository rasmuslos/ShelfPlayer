//
//  PauseIntent.swift
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

struct PauseIntent: AppIntent, AudioPlaybackIntent {
    static let title: LocalizedStringResource = "intent.pause"
    static let description = IntentDescription("intent.pause.description")
    
    func perform() async throws -> some IntentResult {
        #if canImport(SPPlayback)
        guard await AudioPlayer.shared.currentItemID != nil else {
            throw IntentError.noPlaybackItem
        }
        
        await AudioPlayer.shared.pause()
        #else
        throw IntentError.wrongExecutionContext
        #endif
        
        return .result()
    }
}
