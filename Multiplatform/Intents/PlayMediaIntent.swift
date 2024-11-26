//
//  PlayMediaIntent.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import AppIntents
import ShelfPlayerKit

struct PlayMediaIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "intents.playItem.title"
    static var description = IntentDescription("intents.playItem.description")
    
    func perform() async throws -> some IntentResult {
        .result()
    }
}
