//
//  PlayIntent.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import AppIntents
import Defaults

public struct PlayIntent: AppIntent, AudioPlaybackIntent {
    public static let title: LocalizedStringResource = "intent.play"
    public static let description = IntentDescription("intent.play.description")
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        /*
        guard Defaults[.lastListened]?.isPlaying != nil else {
            throw IntentError.noPlaybackItem
        }
        
        RFNotification[.intentChangePlaybackState].send(payload: true)
         */
        return .result()
    }
}
